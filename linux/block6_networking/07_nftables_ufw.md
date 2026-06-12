# Packet Filtering: nftables, ufw, and iptables

## How Linux Packet Filtering Works

Linux packet filtering is built on **netfilter** — kernel hooks that intercept packets at different points in the network stack:

```
NIC → PREROUTING → [routing decision]
                    ↓ (local)        ↓ (forward)
               INPUT chain        FORWARD chain
                    ↓                  ↓
              Local process       POSTROUTING
                    ↓
               OUTPUT chain → POSTROUTING → NIC
```

Each **chain** is a list of rules. Each rule has a **match** (conditions) and a **target** (what to do). Common targets: ACCEPT, DROP, REJECT, LOG, REDIRECT, MASQUERADE.

## iptables: The Classic Tool

iptables organizes rules into **tables** and **chains**:

| Table | Purpose |
|-------|---------|
| `filter` | Default: INPUT, FORWARD, OUTPUT |
| `nat` | Address translation: PREROUTING, POSTROUTING |
| `mangle` | Packet modification |
| `raw` | Before connection tracking |

```bash
# List all rules (verbose, numeric)
sudo iptables -L -n -v

# List a specific chain
sudo iptables -L INPUT -n -v

# List with line numbers
sudo iptables -L INPUT -n --line-numbers

# List the nat table
sudo iptables -t nat -L -n -v
```

### Common iptables Operations

```bash
# Allow incoming SSH
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow established/related connections (stateful firewall)
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Drop all other inbound traffic (default deny)
sudo iptables -P INPUT DROP

# Allow a specific IP
sudo iptables -A INPUT -s 10.0.0.0/8 -j ACCEPT

# Delete a rule by number
sudo iptables -D INPUT 3

# Flush all rules in a chain
sudo iptables -F INPUT

# Insert at a specific position
sudo iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT
```

### Rate Limiting

```bash
# Limit connection attempts (anti-brute-force)
sudo iptables -A INPUT -p tcp --dport 22 -m recent --name SSH --update --seconds 60 --hitcount 5 -j DROP
sudo iptables -A INPUT -p tcp --dport 22 -m recent --name SSH --set -j ACCEPT
```

## nftables: The Modern Replacement

**nftables** replaces iptables, ip6tables, arptables, and ebtables with a unified tool. Ubuntu 22.04+ uses nftables backend for ufw.

```bash
# List all rules
sudo nft list ruleset

# List a specific table
sudo nft list table inet filter

# Show counters
sudo nft -a list ruleset
```

### nftables Rule Structure

```nft
table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;

        iif "lo" accept                          # Allow loopback
        ct state established,related accept      # Allow established
        tcp dport 22 accept                      # Allow SSH
        tcp dport { 80, 443 } accept             # Allow HTTP/HTTPS
        counter drop                             # Count and drop the rest
    }
}
```

```bash
# Add a rule
sudo nft add rule inet filter input tcp dport 8080 accept

# Delete a table
sudo nft delete table inet filter
```

## ufw: Uncomplicated Firewall

**ufw** is a frontend to iptables/nftables designed to be easy to use. It's the recommended tool for Ubuntu.

```bash
# Check status (disabled/active, rules)
sudo ufw status
sudo ufw status verbose
sudo ufw status numbered

# Enable/disable
sudo ufw enable
sudo ufw disable

# Allow a port
sudo ufw allow 22/tcp
sudo ufw allow ssh          # uses /etc/services lookup
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 8080/tcp

# Allow from a specific IP
sudo ufw allow from 192.168.1.0/24
sudo ufw allow from 10.0.0.5 to any port 22

# Deny a port
sudo ufw deny 23/tcp

# Delete a rule
sudo ufw delete allow 8080/tcp
sudo ufw delete 3              # by rule number from 'status numbered'

# Reload rules
sudo ufw reload
```

### ufw Logging

```bash
# Enable logging
sudo ufw logging on
sudo ufw logging medium    # low/medium/high/full

# View ufw log
sudo tail -f /var/log/ufw.log
# or
sudo grep UFW /var/log/kern.log | tail -20
```

### ufw Default Policies

```bash
# Sensible defaults for a server
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

## Checking the Current State (Any Tool)

```bash
# Are there any iptables rules?
sudo iptables -L -n | grep -v '^$' | grep -v 'target\|Chain'

# Are there any nft rules?
sudo nft list ruleset 2>/dev/null

# Is ufw active?
sudo ufw status
```

## Further Reading

- [nftables wiki](https://wiki.nftables.org/wiki-nftables/index.php/Main_Page) — The official nftables documentation covering table families, chain types, verdict maps, sets, and NAT — the canonical reference for everything beyond the basics in this lesson.
- [nft(8) man page](https://man7.org/linux/man-pages/man8/nft.8.html) — Complete syntax reference for nftables rule expressions, match criteria, statement types, and the `nft` CLI subcommands.
- [Moving from iptables to nftables](https://wiki.nftables.org/wiki-nftables/index.php/Moving_from_iptables_to_nftables) — Side-by-side translation guide between iptables and nftables rule syntax, essential for reading legacy rules and understanding the iptables-nft compatibility shim.
- [Ubuntu server firewall guide (ufw)](https://ubuntu.com/server/docs/security-firewall) — Ubuntu's official guide for configuring ufw, covering default policies, application profiles, logging, and the relationship between ufw and the nftables backend.
- [Netfilter project](https://www.netfilter.org/) — Home of the netfilter kernel subsystem that underlies iptables, nftables, and conntrack; documentation covers the hook architecture shown in the packet-flow diagram at the top of this lesson.
