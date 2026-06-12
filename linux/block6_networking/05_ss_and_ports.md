# ss and Port Inspection

## What is ss?

`ss` (**socket statistics**) is the modern replacement for `netstat`. It queries socket information directly from the kernel via netlink, making it faster and more accurate. It shows TCP, UDP, Unix domain sockets, and more.

```bash
# Basic usage: show all sockets
ss

# Most common: show listening TCP ports with process names
ss -tlnp
```

## Essential Options

| Option | Meaning |
|--------|---------|
| `-t` | TCP sockets |
| `-u` | UDP sockets |
| `-x` | Unix domain sockets |
| `-l` | Show only listening sockets |
| `-n` | Don't resolve names (show IPs and port numbers) |
| `-p` | Show process name and PID |
| `-a` | All sockets (listening + connected) |
| `-s` | Summary statistics |
| `-r` | Resolve hostnames (opposite of -n) |
| `-4` | IPv4 only |
| `-6` | IPv6 only |

## Common Command Patterns

```bash
# All listening TCP ports with process names (most used command)
ss -tlnp

# All listening and connected TCP
ss -tnp

# All listening UDP
ss -ulnp

# Unix domain sockets (listening)
ss -xlnp

# All socket types, all states
ss -anp

# Summary statistics
ss -s
```

## Reading ss Output

```bash
ss -tlnp
# Netid  State   Recv-Q Send-Q Local Address:Port   Peer Address:Port  Process
# tcp    LISTEN  0      128    0.0.0.0:22            0.0.0.0:*          users:(("sshd",pid=1234,fd=3))
# tcp    LISTEN  0      511    0.0.0.0:80            0.0.0.0:*          users:(("nginx",pid=5678,fd=6))
# tcp    LISTEN  0      128    127.0.0.1:5432        0.0.0.0:*          users:(("postgres",pid=9012,fd=5))
```

- `Netid` — protocol (tcp, udp, u_str for Unix stream)
- `State` — socket state
- `Recv-Q / Send-Q` — bytes queued (should be 0 for healthy listening socket)
- `Local Address:Port` — `0.0.0.0` means listening on all interfaces
- `Peer Address:Port` — `*` means any peer
- `Process` — process name, PID, and file descriptor

## TCP Socket States

| State | Meaning |
|-------|---------|
| `LISTEN` | Waiting for incoming connections |
| `ESTABLISHED` | Active connection |
| `TIME_WAIT` | Connection closed, waiting for delayed packets |
| `CLOSE_WAIT` | Remote side closed, local side hasn't yet |
| `SYN_SENT` | Sent SYN, waiting for SYN-ACK |
| `SYN_RECV` | Received SYN, sent SYN-ACK |
| `FIN_WAIT1` | Sent FIN, waiting for ACK |
| `FIN_WAIT2` | Received ACK of FIN, waiting for remote FIN |
| `LAST_ACK` | Sent FIN, waiting for final ACK |

```bash
# Count connections in each state
ss -tn | awk 'NR>1 {print $1}' | sort | uniq -c | sort -rn
```

## Filtering by Port, State, or Address

```bash
# Show sockets on port 22
ss -tnp 'sport = :22 or dport = :22'

# Show established connections only
ss -tn state established

# Show TIME_WAIT connections (often indicates high-volume server)
ss -tn state time-wait | wc -l

# Show connections to a specific host
ss -tn dst 8.8.8.8

# Show connections from a specific source port range
ss -tn 'sport >= :1024 and sport <= :2048'
```

## Finding Which Process Owns a Port

```bash
# Which process is listening on port 80?
ss -tlnp | grep ':80'

# Alternative: use lsof
lsof -i :80 2>/dev/null

# Another alternative: fuser
fuser 80/tcp 2>/dev/null
```

## netstat: Legacy Equivalent

`netstat` from the `net-tools` package is still common on older systems:

```bash
# Equivalent to ss -tlnp
netstat -tulpn

# All connections
netstat -anp

# Summary
netstat -s

# Routing table (like ip route)
netstat -rn
```

The `-tulpn` flags: **t**cp, **u**dp, **l**istening, **p**rograms, **n**umeric.

## Practical Scenarios

```bash
# Is anything listening on port 8080?
ss -tlnp | grep ':8080' && echo "port 8080 in use" || echo "port 8080 free"

# Count established connections
ss -tn state established | grep -c ESTAB

# Watch connections in real time
watch -n 1 'ss -tn state established | wc -l'

# Find processes with many connections (potential connection leak)
ss -tnp | grep -oP '(?<=")\w+(?=",)' | sort | uniq -c | sort -rn | head -10

# Check if SSH is listening
ss -tlnp | grep sshd
```

## Further Reading

- [ss(8) man page](https://man7.org/linux/man-pages/man8/ss.8.html) — The authoritative reference for all `ss` filter expressions including state-based filters (`state established`), port ranges, and `dst`/`src` address qualifiers used throughout this lesson.
- [RFC 793 — TCP](https://datatracker.ietf.org/doc/html/rfc793) — The original TCP specification defining all the connection states (`TIME_WAIT`, `CLOSE_WAIT`, `FIN_WAIT1`, etc.) shown in the ss state table.
- [socket(7) man page](https://man7.org/linux/man-pages/man7/socket.7.html) — Explains the socket API, listen backlog semantics (visible in `Recv-Q`/`Send-Q`), and `SO_*` options that appear in `ss -ti` extended output.
- [Arch Wiki: Network Debugging](https://wiki.archlinux.org/title/Network_Debugging) — Practical troubleshooting guide that combines `ss`, `lsof`, and `fuser` for port investigation — the same workflow covered in the "Finding Which Process Owns a Port" section.
