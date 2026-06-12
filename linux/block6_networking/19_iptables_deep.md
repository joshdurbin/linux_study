# iptables Deep Dive

## Overview

`iptables` is the classic Linux firewall and packet-mangling tool. It provides a rule-based framework that hooks into the Linux kernel's `netfilter` subsystem. Although modern Ubuntu 22+ systems use `nftables` as the default backend, `iptables` commands still work either through a compatibility shim (`iptables-nft`) or the legacy backend (`iptables-legacy`). Understanding iptables is essential because:

- Docker, Kubernetes, and many other tools still generate iptables rules
- `iptables-save` output is a universal format you will read in production environments
- The mental model of tables, chains, and rules applies directly to nftables and other modern tools
- Incident response often requires reading and temporarily modifying firewall rules

---

## The netfilter Architecture

Every packet that enters, traverses, or leaves the Linux kernel passes through **netfilter hooks**. iptables attaches its rule evaluation to these hooks.

```
Incoming packet
      │
      ▼
 [PREROUTING]  ← nat (DNAT), mangle, raw
      │
      ├──→ [INPUT] ← filter, mangle        → local process
      │
      └──→ [FORWARD] ← filter, mangle      → outgoing
                                                 │
Outgoing packet ←── [OUTPUT] ← filter, nat, mangle, raw
                                                 │
                         [POSTROUTING] ← nat (SNAT/MASQUERADE), mangle
```

This diagram shows the five **hooks** (also called built-in chains):

| Hook / Chain    | When it fires |
|-----------------|---------------|
| `PREROUTING`    | Before routing decision — can redirect packets |
| `INPUT`         | Packets destined for the local machine |
| `FORWARD`       | Packets being routed through (not to) the machine |
| `OUTPUT`        | Packets originating from local processes |
| `POSTROUTING`   | After routing decision — used for SNAT/MASQUERADE |

---

## Tables

iptables organises rules into **tables**. Each table serves a distinct purpose and is available at specific chains.

### filter (default)

The firewall table. This is the table you use when deciding whether to allow or deny traffic.

Chains: `INPUT`, `FORWARD`, `OUTPUT`

```bash
iptables -t filter -L -v -n      # or just: iptables -L -v -n
```

### nat

Network Address Translation. Used to rewrite source/destination IP addresses and ports.

Chains: `PREROUTING`, `INPUT` (kernel 3.7+), `OUTPUT`, `POSTROUTING`

```bash
iptables -t nat -L -v -n
```

### mangle

Fine-grained packet modification: setting TOS (Type of Service), TTL, MARK, CONNMARK. Used for QoS and policy routing.

Chains: All five chains.

```bash
iptables -t mangle -L -v -n
```

### raw

Evaluated before connection tracking. Used to exempt packets from conntrack with `NOTRACK`.

Chains: `PREROUTING`, `OUTPUT`

```bash
iptables -t raw -L -v -n
```

### security (Linux Security Modules)

Used by SELinux. Rarely touched manually.

---

## Rule Structure

A rule consists of:

```
iptables [-t table] -A CHAIN [match criteria] -j TARGET
```

| Component        | Description |
|-----------------|-------------|
| `-t table`      | Which table (default: filter) |
| `-A CHAIN`      | Append to chain (or `-I` to insert at top) |
| match criteria  | Protocol, source, destination, interface, port, state, etc. |
| `-j TARGET`     | What to do with matching packets |

### Common Match Criteria

```bash
-p tcp                        # protocol
-p udp
-s 192.168.1.0/24             # source IP/CIDR
-d 10.0.0.1                   # destination IP
-i eth0                        # input interface
-o eth0                        # output interface
--dport 80                    # destination port (requires -p tcp/udp)
--sport 1024:65535             # source port range
-m state --state NEW,ESTABLISHED,RELATED   # connection tracking state
-m multiport --dports 80,443  # multiple ports
-m conntrack --ctstate ESTABLISHED        # newer conntrack module
```

### Targets (What to Do)

| Target        | Action |
|---------------|--------|
| `ACCEPT`      | Allow the packet through |
| `DROP`        | Silently discard the packet |
| `REJECT`      | Discard and send ICMP error back to sender |
| `LOG`         | Log to kernel log (syslog/journald) and continue evaluation |
| `RETURN`      | Stop traversing the current chain, return to calling chain |
| `MASQUERADE`  | SNAT where the source IP is dynamic (e.g., DHCP WAN) |
| `SNAT`        | Static source NAT |
| `DNAT`        | Destination NAT — redirect incoming connections |
| `REDIRECT`    | Redirect to local port (convenience form of DNAT) |

---

## Chain Policies

Each built-in chain has a **default policy** that applies when no rule matches:

```bash
iptables -P INPUT DROP     # default deny (careful — locks you out!)
iptables -P INPUT ACCEPT   # default allow
```

Custom chains (user-defined) have no policy — packets that fall off the end `RETURN` to the calling chain.

---

## Viewing Rules

```bash
# List with packet/byte counters, numeric IPs/ports
iptables -L -v -n

# Include line numbers (useful for -D delete by number)
iptables -L -v -n --line-numbers

# Specific chain
iptables -L INPUT -v -n

# Specific table
iptables -t nat -L -v -n
iptables -t mangle -L -v -n
iptables -t raw -L -v -n

# iptables-save format (most readable for scripting)
iptables-save
iptables-save -t filter
```

---

## Adding and Deleting Rules

```bash
# Append a rule to the end of INPUT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Insert at position 1 (top) of INPUT
iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT

# Delete by rule specification
iptables -D INPUT -p tcp --dport 22 -j ACCEPT

# Delete by line number (get numbers with --line-numbers)
iptables -D INPUT 3

# Flush (delete all rules) from a chain
iptables -F INPUT

# Flush all chains in all tables
iptables -F
iptables -t nat -F
iptables -t mangle -F

# Delete user-defined chains
iptables -X

# Reset packet/byte counters
iptables -Z
```

---

## Connection Tracking (conntrack)

iptables integrates with the `conntrack` subsystem (introduced in lesson 17). The `state` and `conntrack` modules let you write stateful rules:

```bash
# Allow established and related traffic (essential for stateful firewall)
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow new SSH connections
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT

# Default deny
iptables -P INPUT DROP
```

**conntrack states:**

| State       | Meaning |
|-------------|---------|
| `NEW`       | First packet of a new connection |
| `ESTABLISHED` | Part of an already-seen connection |
| `RELATED`   | Related to an established connection (e.g., FTP data) |
| `INVALID`   | Cannot be identified |

---

## NAT: MASQUERADE, SNAT, DNAT

### MASQUERADE (Dynamic SNAT)

Used when the outgoing IP is dynamic (home router, DHCP WAN):

```bash
# Share internet from eth0 to internal network
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sysctl -w net.ipv4.ip_forward=1
```

### SNAT (Static Source NAT)

```bash
# Rewrite source IP for packets leaving eth0
iptables -t nat -A POSTROUTING -o eth0 -j SNAT --to-source 203.0.113.1
```

### DNAT (Destination NAT / Port Forwarding)

```bash
# Forward incoming port 80 on eth0 to internal server 192.168.1.10:8080
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 \
  -j DNAT --to-destination 192.168.1.10:8080

# Also need FORWARD rule to allow it
iptables -A FORWARD -p tcp -d 192.168.1.10 --dport 8080 -j ACCEPT
```

### REDIRECT (Local Port Redirect)

```bash
# Transparently redirect port 80 to 8080 on localhost
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
```

---

## Logging

The LOG target is invaluable for debugging:

```bash
# Log dropped packets with a prefix tag
iptables -A INPUT -p tcp --dport 8888 -j LOG --log-prefix "IPTABLES-DROP: " --log-level 4

# Then drop them
iptables -A INPUT -p tcp --dport 8888 -j DROP
```

Log entries appear in:
```bash
journalctl -k | grep IPTABLES-DROP
dmesg | grep IPTABLES-DROP
```

**Important:** LOG is a non-terminating target — the packet continues to the next rule after logging. Always pair LOG with DROP/ACCEPT.

---

## User-Defined Chains

You can create custom chains to organise rules and avoid repetition:

```bash
# Create a chain
iptables -N MY_CHAIN

# Add rules to it
iptables -A MY_CHAIN -p tcp --dport 443 -j ACCEPT
iptables -A MY_CHAIN -j DROP

# Jump to it from INPUT
iptables -A INPUT -i eth0 -j MY_CHAIN

# Delete user chain (must be empty and unreferenced)
iptables -F MY_CHAIN
iptables -X MY_CHAIN
```

---

## Saving and Restoring Rules

Rules added with `iptables` do not survive a reboot unless saved.

### iptables-save

```bash
# Print all rules to stdout in restore format
iptables-save

# Save to file
iptables-save > /etc/iptables/rules.v4

# Save specific table
iptables-save -t nat > /etc/iptables/nat.rules
```

### iptables-restore

```bash
# Restore rules from file (atomically replaces current rules)
iptables-restore < /etc/iptables/rules.v4

# Append instead of replace
iptables-restore --noflush < /etc/iptables/rules.v4
```

### iptables-save Format

```
# Generated by iptables-save v1.8.7
*filter
:INPUT ACCEPT [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
-A INPUT -p tcp --dport 22 -j ACCEPT
-A INPUT -j DROP
COMMIT
```

Each table starts with `*tablename` and ends with `COMMIT`. Chain policies use `:CHAINNAME POLICY [packets:bytes]`.

---

## Docker and iptables

Docker heavily uses iptables for container networking. Run `iptables-save` on a Docker host and you will see:

```
*nat
:DOCKER - [0:0]
-A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER
-A OUTPUT ! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j DOCKER
-A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
-A DOCKER -i docker0 -j RETURN
...
*filter
:DOCKER - [0:0]
:DOCKER-ISOLATION-STAGE-1 - [0:0]
:DOCKER-ISOLATION-STAGE-2 - [0:0]
:DOCKER-USER - [0:0]
-A FORWARD -j DOCKER-USER
-A FORWARD -j DOCKER-ISOLATION-STAGE-1
```

Key Docker chains:
- `DOCKER` — per-container port publishing rules
- `DOCKER-USER` — a chain Docker leaves empty for user customisation; rules here run before Docker's rules
- `DOCKER-ISOLATION-STAGE-1/2` — inter-network isolation
- MASQUERADE rule for `172.17.0.0/16` — allows containers to reach the internet

**Never flush the nat or filter table on a Docker host** without saving first, as it will break all container networking.

---

## iptables on Ubuntu 22+: nftables Backend

Ubuntu 22.04+ ships `iptables` as a wrapper around `nftables`:

```bash
# Check which backend is active
update-alternatives --display iptables

# Use legacy backend explicitly
iptables-legacy -L
iptables-legacy-save

# Switch system default to legacy
update-alternatives --set iptables /usr/sbin/iptables-legacy
```

The `iptables-nft` backend translates iptables rules to nftables internally. Performance is generally equivalent, but mixing `iptables-nft` and `iptables-legacy` on the same system will produce split rule sets that interfere with each other.

---

## Counting Packets and Bytes

```bash
# Verbose listing shows packet and byte counts per rule
iptables -L -v -n

# iptables-save includes counts in chain policy lines
# :INPUT ACCEPT [1234:567890]  → 1234 packets, 567890 bytes

# Zero counters for a chain
iptables -Z INPUT

# Zero all counters
iptables -Z
```

---

## Practical Firewall Patterns

### Minimal Secure Server

```bash
# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established/related
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Drop everything else
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
```

### Rate Limiting (brute force protection)

```bash
# Allow SSH but limit new connections
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW \
  -m recent --set --name SSH
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW \
  -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
```

### Port Knocking Skeleton

```bash
iptables -N KNOCKING
iptables -N GATE1
iptables -N GATE2
iptables -N PASSED

iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j KNOCKING
iptables -A KNOCKING -m recent --name GATE1 --rcheck -j GATE2
iptables -A KNOCKING -p tcp --dport 7000 -m recent --name GATE1 --set -j DROP
iptables -A GATE2 -m recent --name GATE2 --rcheck -j PASSED
iptables -A GATE2 -p tcp --dport 8000 -m recent --name GATE2 --set -j DROP
iptables -A PASSED -p tcp --dport 9000 -j ACCEPT
```

---

## Troubleshooting Tips

| Problem | Approach |
|---------|----------|
| Can't reach a service | `iptables -L -v -n` — check DROP counters incrementing |
| Rules not persisting | Install `iptables-persistent` or write `iptables-restore` to systemd unit |
| Docker rules missing | Never run `iptables -F` blindly; restart Docker to regenerate |
| LOG rules silent | Check `journalctl -k`; ensure the LOG rule is before the DROP rule |
| nftables vs legacy confusion | Check `update-alternatives --display iptables` |
| REJECT vs DROP | REJECT sends RST/ICMP (faster client failure); DROP causes timeout |

## Further Reading

- [iptables(8) man page](https://man7.org/linux/man-pages/man8/iptables.8.html) — The authoritative reference for iptables flags, chain policies, and rule syntax; `iptables-extensions(8)` covers every match module (`conntrack`, `recent`, `hashlimit`, `multiport`) and target (`MASQUERADE`, `REDIRECT`, `LOG`).
- [Netfilter HOWTO](https://www.netfilter.org/documentation/HOWTO/netfilter-hacking-HOWTO.html) — The netfilter developer guide explaining the five hooks, packet traversal order, and how tables and chains attach to hooks — the background theory for the architecture diagram in this lesson.
- [Arch Wiki: iptables](https://wiki.archlinux.org/title/Iptables) — Practical iptables guide with examples for stateful firewalls, NAT, logging, and persistence — closely matches the firewall patterns section of this lesson.
- [kernel.org: netfilter documentation](https://www.kernel.org/doc/html/latest/networking/netfilter.html) — Kernel-level netfilter documentation covering hook priorities, the nf_tables backend, and how iptables-nft translates rules internally on Ubuntu 22+.
- [Julia Evans: An SRE's guide to basic Linux networking](https://jvns.ca/blog/2022/09/22/an-sre-s-guide-to-basic-linux-networking/) — Covers iptables fundamentals from an SRE perspective, including how to read Docker's DOCKER-USER chain and why iptables -F is dangerous on container hosts.

---

## Quick Reference

```bash
# List all rules, all tables
for t in filter nat mangle raw; do
  echo "=== TABLE: $t ==="; iptables -t $t -L -v -n; done

# Add a rule
iptables -A INPUT -p tcp --dport PORT -j DROP

# Delete a rule
iptables -D INPUT -p tcp --dport PORT -j DROP

# Save / restore
iptables-save > rules.v4
iptables-restore < rules.v4

# Show Docker rules
iptables-save | grep -i docker

# Show packet counts
iptables -L -v -n | sort -rn -k1 | head -20
```
