# /etc/hosts and Local Name Resolution

`/etc/hosts` is a flat-file DNS override checked before querying a nameserver. It's one of the first places the resolver looks — understanding it and the full lookup chain makes DNS debugging much faster.

## The Full Resolution Order

Controlled by `/etc/nsswitch.conf`:

```bash
grep "^hosts" /etc/nsswitch.conf
# hosts: files dns

# "files" = /etc/hosts   "dns" = /etc/resolv.conf servers
# Order matters: files is checked first by default
```

Other possible values: `myhostname` (systemd hostname), `mdns4_minimal` (mDNS/Bonjour), `resolve` (systemd-resolved).

## /etc/hosts Format

```
# <IP>         <canonical-name>    [alias ...]
127.0.0.1      localhost
127.0.1.1      myhostname.local    myhostname
::1            localhost           ip6-localhost

# Custom entries
10.0.0.5       db.internal         db
192.168.1.100  gitlab.corp.example.com
```

Rules:
- One IP per line, one or more hostnames
- `#` comments
- First hostname on the line is the canonical name; others are aliases
- IPv4 and IPv6 entries are independent — you can have both for the same name
- Matches are **exact** — no wildcards, no regex

## Reading and Modifying

```bash
cat /etc/hosts

# Add a temporary entry (requires root)
echo "1.2.3.4 test.local" | sudo tee -a /etc/hosts

# Verify it resolves
getent hosts test.local     # queries nsswitch (files + dns), shows result + source
ping -c1 test.local
```

`getent hosts` is more reliable than `ping` for testing name resolution — it uses the same NSS stack your applications use and shows the resolved IP.

## Common Use Cases

```bash
# Block a domain (point to loopback)
echo "0.0.0.0 ads.tracker.example.com" | sudo tee -a /etc/hosts

# Override a production hostname locally (for testing)
echo "127.0.0.1 api.myapp.com" | sudo tee -a /etc/hosts

# Map a container name to its IP (before Docker DNS was standard)
echo "172.17.0.5 redis-container" | sudo tee -a /etc/hosts

# Kubernetes /etc/hosts is injected per-pod (dnsPolicy: None uses this)
```

## systemd-resolved and /etc/resolv.conf

On Ubuntu 22.04+ the relationship is:

```
/etc/resolv.conf → symlink → /run/systemd/resolve/stub-resolv.conf
                              nameserver 127.0.0.53   ← systemd-resolved stub

Application → glibc resolver → 127.0.0.53 → systemd-resolved → upstream DNS
```

```bash
# Real upstream DNS servers (not just the stub)
resolvectl status
resolvectl dns                    # current DNS servers per interface

# What would this hostname resolve to, and via which path?
resolvectl query db.internal

# Flush the DNS cache
sudo resolvectl flush-caches

# Check if a specific name is being resolved from /etc/hosts vs DNS
getent -s files hosts test.local   # force "files" source only
getent -s dns hosts example.com    # force DNS only
```

## /etc/resolv.conf Directives

```
nameserver 1.1.1.1          # upstream DNS (up to 3 lines)
nameserver 8.8.8.8

search corp.example.com     # appended when resolving short names
                            # ping "db" tries "db.corp.example.com" first

domain corp.example.com     # single domain (mutually exclusive with search)

options ndots:5             # names with < 5 dots get search appended first
options timeout:2           # seconds per DNS query attempt
options attempts:3          # retries before giving up
options rotate              # round-robin across nameservers
```

## Troubleshooting Name Resolution

```bash
# Step 1: does /etc/hosts have an entry?
getent -s files hosts hostname

# Step 2: what does full NSS resolution return?
getent hosts hostname

# Step 3: what does pure DNS say?
dig hostname @8.8.8.8 +short     # bypass local resolver, query Google directly
nslookup hostname 8.8.8.8

# Step 4: check nsswitch.conf order
grep hosts /etc/nsswitch.conf

# Step 5: check resolv.conf
cat /etc/resolv.conf
resolvectl status 2>/dev/null

# Step 6: check if systemd-resolved is running
systemctl status systemd-resolved 2>/dev/null
```

## Host File Consistency Checks

```bash
# Find duplicate entries
sort /etc/hosts | uniq -d

# Find entries for a specific IP
grep "^10\." /etc/hosts

# Count non-comment entries
grep -vc "^#\|^$" /etc/hosts
```

## Further Reading

- [hosts(5) man page](https://man7.org/linux/man-pages/man5/hosts.5.html) — Documents the exact `/etc/hosts` file format including canonical name vs alias ordering and IPv4/IPv6 coexistence rules.
- [resolv.conf(5) man page](https://man7.org/linux/man-pages/man5/resolv.conf.5.html) — Complete reference for all resolver directives (`nameserver`, `search`, `domain`, `ndots`, `timeout`, `rotate`) that control how DNS queries are formed and retried.
- [nsswitch.conf(5) man page](https://man7.org/linux/man-pages/man5/nsswitch.conf.5.html) — Documents the Name Service Switch configuration that controls whether `files` (hosts) or `dns` is consulted first, and how `myhostname` and `mdns` fit into the lookup chain.
- [systemd-resolved documentation](https://www.freedesktop.org/software/systemd/man/latest/systemd-resolved.service.html) — Covers the stub resolver at `127.0.0.53`, `resolvectl status/query/flush-caches`, and how `/etc/resolv.conf` is managed on Ubuntu 22.04+ systems.
