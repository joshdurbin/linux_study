# nmap — Network Mapper

nmap is the standard tool for network discovery and security auditing. It maps hosts, open ports, running services, OS versions, and can run scripts against discovered services.

> **Important:** Only scan networks and hosts you own or have explicit written permission to scan. Unauthorized scanning is illegal in most jurisdictions and violates terms of service.

## Host Discovery

```bash
# Ping scan — find live hosts, no port scan
nmap -sn 192.168.1.0/24

# Skip ping (assume all hosts are up)
nmap -Pn hostname

# ARP scan (faster on local network, root required)
nmap -PR 192.168.1.0/24

# Disable DNS resolution (faster)
nmap -n hostname
```

## Port Scan Types

```bash
# SYN scan (stealthy, root required) — default when root
nmap -sS hostname

# TCP connect scan (no root needed) — default without root
nmap -sT hostname

# UDP scan (slower, needs root)
nmap -sU hostname

# ACK scan (detect firewall rules — FILTERED vs UNFILTERED)
nmap -sA hostname
```

## Port Specification

```bash
nmap hostname              # top 1000 ports
nmap -p 22,80,443 hostname # specific ports
nmap -p 1-1000 hostname    # range
nmap -p- hostname          # all 65535 ports
nmap -p U:53,T:80 hostname # UDP:53 and TCP:80
nmap --top-ports 100 hostname
```

## Port States

| State | Meaning |
|-------|---------|
| `open` | Application is accepting connections |
| `closed` | Port reachable, no application listening |
| `filtered` | Firewall dropping packets — nmap can't tell if open |
| `unfiltered` | Port reachable, state unknown (ACK scan) |
| `open\|filtered` | Can't distinguish between open and filtered (UDP) |

## Service and Version Detection

```bash
# Service version fingerprinting
nmap -sV hostname

# OS detection (root required)
nmap -O hostname

# Both together
nmap -sV -O hostname

# Intensity: 0-9 (default 7)
nmap -sV --version-intensity 9 hostname
```

## Timing Templates

```bash
nmap -T0 hostname   # paranoid (very slow, evades IDS)
nmap -T1 hostname   # sneaky
nmap -T2 hostname   # polite (reduced bandwidth)
nmap -T3 hostname   # normal (default)
nmap -T4 hostname   # aggressive (assumes fast network)
nmap -T5 hostname   # insane (may miss ports)
```

## NSE — Nmap Scripting Engine

```bash
# Default scripts (safe, informational)
nmap -sC hostname

# Specific script
nmap --script http-title hostname
nmap --script ssl-cert hostname -p 443
nmap --script vuln hostname        # vulnerability checks (intrusive!)

# Script categories: safe, intrusive, vuln, exploit, auth, discovery, brute
nmap --script "safe and discovery" hostname

# List available scripts
ls /usr/share/nmap/scripts/ | grep http
```

## Output Formats

```bash
nmap -oN scan.txt hostname     # normal text
nmap -oX scan.xml hostname     # XML (parseable)
nmap -oG scan.gnmap hostname   # grepable
nmap -oA scan hostname         # all three formats (scan.nmap, scan.xml, scan.gnmap)
```

## Useful Combinations

```bash
# Quick aggressive scan of a host
nmap -sV -sC -T4 -p- hostname

# Fast network sweep with OS + version
sudo nmap -sV -O -T4 192.168.1.0/24

# Find all SSH servers in a subnet
nmap -p 22 --open 192.168.1.0/24

# Find HTTP/HTTPS servers
nmap -p 80,443,8080,8443 --open 192.168.0.0/24

# Firewall bypass: fragment packets
nmap -f hostname

# Scan through a SOCKS proxy
nmap --proxies socks4://localhost:1080 hostname
```

## Interpreting Output

```
PORT    STATE  SERVICE  VERSION
22/tcp  open   ssh      OpenSSH 8.9p1 Ubuntu
80/tcp  closed http
443/tcp filtered https

OS details: Linux 5.15 - 5.19
```

## Further Reading

- [Nmap Reference Guide (free book)](https://nmap.org/book/man.html) — The comprehensive free nmap manual covering every scan type, timing template, host discovery method, and output format described in this lesson — the authoritative reference.
- [NSE script library](https://nmap.org/nsedoc/) — Searchable documentation for all Nmap Scripting Engine scripts, organized by category (safe, intrusive, vuln, auth, discovery), with examples for each script.
- [Arch Wiki: Nmap](https://wiki.archlinux.org/title/Nmap) — Practical guide covering installation, scan type selection, and common use-case examples including service enumeration and firewall rule detection.
