# Sockets — Unix and Network

A socket is a file descriptor representing one endpoint of a communication channel. The same `read()`/`write()` interface used for files works on sockets — the kernel routes bytes to the right destination.

## Socket Families

| Family | Constant | Use |
|--------|----------|-----|
| Internet IPv4 | `AF_INET` | TCP/UDP over IPv4 |
| Internet IPv6 | `AF_INET6` | TCP/UDP over IPv6 |
| Unix domain | `AF_UNIX` | IPC on the same host |
| Netlink | `AF_NETLINK` | Kernel↔userspace (iproute2 uses this) |
| Packet | `AF_PACKET` | Raw ethernet frames (tcpdump uses this) |

## Socket Types

| Type | Behaviour |
|------|-----------|
| `SOCK_STREAM` | TCP — ordered, reliable, connection-oriented |
| `SOCK_DGRAM` | UDP — unordered, unreliable, connectionless |
| `SOCK_RAW` | Raw IP — bypass transport layer (ping, traceroute) |
| `SOCK_SEQPACKET` | Like STREAM but preserves message boundaries |

## The Socket Lifecycle

```
Server side:                        Client side:

socket()  ← create FD               socket()
  │                                    │
bind()    ← assign address            │
  │                                    │
listen()  ← mark as passive           │
  │                                    │
accept()  ← block until connect ◄──── connect()
  │                                    │
read()/write()  ◄──────────────────►  read()/write()
  │                                    │
close()                               close()
```

## Unix Domain Sockets

Sockets backed by a filesystem path instead of an IP address. Faster than loopback TCP (no network stack), support credential passing:

```bash
# List Unix domain sockets
ss -x                          # all Unix sockets
ss -xlnp                       # listening Unix sockets with process names
lsof -U                        # lsof view

# Common Unix socket paths
ls -la /var/run/docker.sock    # Docker daemon
ls -la /run/systemd/private/   # systemd internal sockets
ls -la /tmp/.s.PGSQL.5432      # PostgreSQL

# Inspect with socat
socat - UNIX-CONNECT:/var/run/docker.sock  # interactive
echo "" | socat - UNIX-CONNECT:/path/to.sock,crnl  # one-shot
```

## /proc/net — Socket Internals

```bash
# All TCP sockets (hex encoded)
cat /proc/net/tcp
cat /proc/net/tcp6     # IPv6
cat /proc/net/udp

# Unix domain sockets
cat /proc/net/unix

# Column meanings for /proc/net/tcp:
# sl  local_address  rem_address  st  tx_queue:rx_queue  ...  inode
# st=0A means LISTEN (hex), st=01 means ESTABLISHED
```

Convert hex addresses:
```bash
# /proc/net/tcp local_address 0100007F:0050 = 127.0.0.1:80
python3 -c "import socket,struct; \
  print(socket.inet_ntoa(struct.pack('<I', int('0100007F',16))), int('0050',16))"
```

## Socket Options

```bash
# See options on a live socket with ss
ss -tiO  # internal TCP state
ss -mnop  # memory, process, options

# Important socket options (set with setsockopt()):
SO_REUSEADDR   # allow bind to recently-closed port (avoids TIME_WAIT issues)
SO_REUSEPORT   # allow multiple processes to bind the same port (load balancing)
SO_KEEPALIVE   # send keepalive probes on idle connections
TCP_NODELAY    # disable Nagle algorithm (lower latency, more packets)
TCP_CORK       # buffer until full MSS (higher throughput, more latency)
SO_SNDBUF      # send buffer size
SO_RCVBUF      # receive buffer size
SO_LINGER      # behaviour on close() with unsent data
```

## Socket State Machine (TCP)

```
CLOSED → LISTEN (server after listen())
       → SYN_SENT (client after connect())
SYN_SENT → ESTABLISHED (after SYN-ACK)
ESTABLISHED → FIN_WAIT_1 → FIN_WAIT_2 → TIME_WAIT → CLOSED (active close)
ESTABLISHED → CLOSE_WAIT → LAST_ACK → CLOSED (passive close)
```

```bash
ss -tan state time-wait   # all sockets in TIME_WAIT
ss -tan state established 'dport = :443'  # HTTPS connections
```

## Observing Sockets with strace

```bash
# See socket syscalls made by curl
strace -e socket,connect,bind,accept,read,write curl https://example.com 2>&1 | head -30
```

## Abstract Namespace Unix Sockets

A Unix socket whose path begins with `\0` — no filesystem entry, removed automatically when all FDs close:

```bash
ss -xlnp | grep '@'   # abstract namespace sockets shown with @
# Used by: X11, DBus, Chrome, Android
```

## Further Reading

- [socket(7) — man7.org](https://man7.org/linux/man-pages/man7/socket.7.html) — the overview man page for socket programming: all families (`AF_INET`, `AF_UNIX`, `AF_NETLINK`, `AF_PACKET`), types, socket options (`SO_REUSEADDR`, `SO_KEEPALIVE`, `SO_SNDBUF`), and `/proc/net` entries.
- [tcp(7) — man7.org](https://man7.org/linux/man-pages/man7/tcp.7.html) — covers every TCP socket option: `TCP_NODELAY`, `TCP_CORK`, `TCP_KEEPIDLE`, `TCP_FASTOPEN`, `TCP_INFO`, and the `/proc/sys/net/ipv4/tcp_*` tunables that govern TCP behavior.
- [unix(7) — man7.org](https://man7.org/linux/man-pages/man7/unix.7.html) — documents Unix domain socket semantics: abstract vs pathname sockets, `SO_PEERCRED` for credential passing, `SOCK_SEQPACKET`, and autobind behavior.
- [Beej's Guide to Network Programming](https://beej.us/guide/bgnet/) — the definitive free guide to Berkeley sockets: the full server/client lifecycle, `getaddrinfo`, non-blocking I/O, `select`/`poll`, and platform portability — the best introduction to the socket API covered in this lesson.
