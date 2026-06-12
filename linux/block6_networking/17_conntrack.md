# conntrack — Connection Tracking

The Linux netfilter connection tracking subsystem records all active network connections. It's what makes stateful firewalls, NAT, and Docker networking possible. Without conntrack, `iptables` would have no way to distinguish a legitimate reply from an unsolicited incoming packet.

## How conntrack Works

Every packet entering the kernel's network stack is checked against the conntrack table. If no matching entry exists, a new connection record is created. Subsequent packets belonging to the same flow match the existing entry and are fast-pathed.

```
Incoming packet
    ↓
conntrack lookup (src IP, dst IP, src port, dst port, protocol)
    ├── Entry found → fast-path, mark as ESTABLISHED
    └── No entry → create new entry, apply firewall rules
```

The conntrack entry tracks the connection **state** and any NAT translation applied to it.

## Connection States

| State | Meaning |
|-------|---------|
| `NEW` | First packet of a connection (SYN for TCP) |
| `ESTABLISHED` | Both directions have been seen; traffic is flowing |
| `RELATED` | Related to an established connection (e.g., FTP data channel) |
| `INVALID` | Doesn't match any connection — usually dropped |
| `CLOSE_WAIT` | TCP: FIN received, waiting for local close |
| `TIME_WAIT` | TCP: waiting for late packets after close |

## conntrack CLI

```bash
# Install if needed
sudo apt-get install -y conntrack

# List all tracked connections
sudo conntrack -L

# List only TCP connections
sudo conntrack -L -p tcp

# List only ESTABLISHED connections
sudo conntrack -L --state ESTABLISHED

# List connections to/from a specific IP
sudo conntrack -L --src 192.168.1.100
sudo conntrack -L --dst 8.8.8.8

# Count entries in the table
sudo conntrack -C

# Watch conntrack events in real time
sudo conntrack -E
# Shows: [NEW], [UPDATE], [DESTROY] events as connections change
```

### Reading conntrack Output

```
tcp      6 431999 ESTABLISHED src=192.168.1.10 dst=93.184.216.34 sport=54321 dport=443
         [UNREPLIED] src=93.184.216.34 dst=192.168.1.10 sport=443 dport=54321
         mark=0 use=1

# Fields:
# tcp            — protocol
# 6              — protocol number (6=TCP)
# 431999         — timeout in seconds before this entry is removed
# ESTABLISHED    — connection state
# src/dst/sport/dport — original direction (what the client sent)
# [UNREPLIED]    — reverse direction (what the server would reply with)
#   after ESTABLISHED: both directions have been seen
```

## /proc/net/nf_conntrack — Raw Kernel Table

```bash
# Read the conntrack table directly (no tool required)
sudo cat /proc/net/nf_conntrack | head -5

# Count entries
sudo wc -l /proc/net/nf_conntrack

# Count ESTABLISHED TCP only
sudo awk '$4 == "ESTABLISHED"' /proc/net/nf_conntrack | wc -l
```

## Key Tuning Parameters

```bash
# Current table size limits
sysctl net.netfilter.nf_conntrack_max        # max entries in the table
sysctl net.netfilter.nf_conntrack_count      # current count

# Bucket count (hash table size — should be nf_conntrack_max / 4)
cat /sys/module/nf_conntrack/parameters/hashsize

# Per-protocol timeouts (seconds)
sysctl net.netfilter.nf_conntrack_tcp_timeout_established   # default: 432000 (5 days!)
sysctl net.netfilter.nf_conntrack_tcp_timeout_time_wait     # default: 120
sysctl net.netfilter.nf_conntrack_udp_timeout               # default: 30
sysctl net.netfilter.nf_conntrack_udp_timeout_stream        # default: 180

# Tune for high-connection-rate environments
sudo sysctl -w net.netfilter.nf_conntrack_max=524288
sudo sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=600
sudo sysctl -w net.netfilter.nf_conntrack_tcp_timeout_time_wait=60
```

## conntrack Table Exhaustion

When `nf_conntrack_count` reaches `nf_conntrack_max`, new connections are dropped silently with the kernel message:

```
nf_conntrack: table full, dropping packet
```

```bash
# Monitor for exhaustion
watch -n1 'echo "count: $(sysctl -n net.netfilter.nf_conntrack_count) / max: $(sysctl -n net.netfilter.nf_conntrack_max)"'

# Check kernel log for table-full messages
dmesg | grep "nf_conntrack: table full"
journalctl -k | grep "nf_conntrack"
```

## NAT and conntrack

NAT rules (MASQUERADE, DNAT) store the translation in the conntrack entry so replies can be un-translated automatically:

```bash
# See NAT translations in the conntrack table
sudo conntrack -L -n 2>/dev/null | head -10
# Shows: src=10.0.0.2 → translated to src=203.0.113.1 (MASQUERADE)

# conntrack is why Docker networking works:
# Container 172.17.0.2 → MASQUERADE → host IP → internet
# Reply comes back to host IP → conntrack remembers → forwards to 172.17.0.2
```

## Deleting conntrack Entries

```bash
# Delete a specific connection (forces re-evaluation by firewall rules)
sudo conntrack -D -p tcp --src 192.168.1.100 --dst 8.8.8.8 --sport 54321 --dport 443

# Delete all TIME_WAIT entries (reclaim table space)
sudo conntrack -D --state TIME_WAIT

# Flush the entire conntrack table (use with caution — drops all established connections)
sudo conntrack -F
```

## Docker/Kubernetes and conntrack

Docker uses conntrack extensively:

```bash
# See container connections in conntrack
sudo conntrack -L | grep "172.17"      # Docker bridge subnet

# The MASQUERADE rule creates conntrack entries
sudo iptables -t nat -L POSTROUTING -n -v
```

Known issue: conntrack's per-CPU locks can become a bottleneck at very high packet rates (>1M packets/second). Solutions: increase `nf_conntrack_max`, use RSS/RPS (block7/13) to spread load, or switch to `nf_conntrack_frag6_timeout_unconfirmed` for connection-less protocols.

## Further Reading

- [kernel.org: netfilter conntrack sysctl](https://www.kernel.org/doc/html/latest/networking/nf_conntrack-sysctl.html) — Definitive documentation for every `net.netfilter.nf_conntrack_*` sysctl parameter including timeouts, table size, and hash configuration covered in the tuning section.
- [conntrack-tools documentation](https://conntrack-tools.netfilter.org/) — Official docs for the `conntrack` CLI and `conntrackd` daemon, covering all `--state`, `--src`, `--dst` filter flags and the event streaming format from `conntrack -E`.
- [conntrack(8) man page](https://man7.org/linux/man-pages/man8/conntrack.8.html) — Complete reference for all conntrack CLI operations (`-L`, `-D`, `-F`, `-E`, `-C`) and the output field format including the `[UNREPLIED]` and NAT translation lines.
- [LWN: Connection tracking in netfilter](https://lwn.net/Articles/358835/) — In-depth article on how the conntrack subsystem works internally, explaining the state machine, flow hash table, and why table exhaustion causes silent packet drops.
