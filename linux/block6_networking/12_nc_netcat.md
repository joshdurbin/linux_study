# nc / ncat — Netcat

Netcat (`nc`) is the "TCP/IP Swiss army knife" — a bare-metal tool for reading and writing raw data across network connections. `ncat` is the modern rewrite from the nmap project with added TLS and proxy support.

## Client Mode

```bash
# Connect to a TCP port
nc hostname 80
nc -v hostname 443     # verbose: shows connection info

# Send HTTP request manually
printf "GET / HTTP/1.0\r\nHost: example.com\r\n\r\n" | nc example.com 80

# Test port reachability (exit immediately)
nc -zv hostname 22     # -z = zero I/O (scan), -v = verbose
nc -zv hostname 22 80 443          # multiple ports
nc -zv hostname 20-25              # port range

# UDP
nc -u hostname 53      # UDP mode
echo "" | nc -u -w1 8.8.8.8 53    # UDP with 1s timeout
```

## Server (Listener) Mode

```bash
# Listen on TCP port 4444
nc -l 4444             # listen once
nc -lk 4444            # -k: keep listening after connection closes (ncat)

# UDP listener
nc -lu 5005

# One-shot echo server
nc -l 9999 | cat
```

## File Transfer

```bash
# Receiver
nc -l 9999 > received_file.tar.gz

# Sender (run after receiver is listening)
nc hostname 9999 < file.tar.gz

# With progress
pv file.tar.gz | nc hostname 9999
```

## Port Scanning

```bash
# TCP scan — check if ports are open
nc -zv hostname 20-25 2>&1 | grep succeeded

# Faster with timeout
nc -zvw2 hostname 1-1000 2>&1 | grep succeeded
```

## Chat / Relay

```bash
# Simple two-way chat
# Host A: nc -l 5555
# Host B: nc hostA 5555
# Type on either side — appears on the other

# Relay: forward connections from port 8080 to internal:80
mkfifo /tmp/nc-pipe
nc -l 8080 < /tmp/nc-pipe | nc internal.host 80 > /tmp/nc-pipe
```

## ncat (nmap's Netcat)

`ncat` extends `nc` with TLS, multiple connections, and proxy support:

```bash
# TLS connection
ncat --ssl hostname 443

# TLS listener (with cert)
ncat --ssl --ssl-cert server.crt --ssl-key server.key -l 4443

# Allow multiple connections (broker mode)
ncat --broker -l 5555

# Connect through SOCKS5 proxy
ncat --proxy localhost:1080 --proxy-type socks5 destination 80
```

## Key Flags Comparison

| Flag | nc (BSD) | nc (GNU) | ncat |
|------|----------|----------|------|
| Listen | `-l -p PORT` | `-l PORT` | `-l PORT` |
| UDP | `-u` | `-u` | `-u` |
| Zero I/O | `-z` | `-z` | `-z` |
| Keep open | — | — | `-k` |
| TLS | No | No | `--ssl` |
| Verbose | `-v` | `-v` | `-v` |

## Common Patterns

```bash
# Test if a service is accepting connections
nc -zv db.host 5432 && echo "PostgreSQL reachable"

# Wait for a service to come up (useful in scripts)
until nc -z localhost 8080; do sleep 1; done; echo "service ready"

# Send a UDP syslog message
echo "<14>test message" | nc -u localhost 514

# Hex dump of raw response
nc hostname 80 | xxd | head
```

## Further Reading

- [ncat(1) man page](https://man7.org/linux/man-pages/man1/ncat.1.html) — The authoritative ncat reference covering TLS flags (`--ssl`, `--ssl-cert`), proxy support, broker mode, and the `--keep-open` flag for persistent listeners.
- [Ncat guide](https://nmap.org/ncat/guide/) — The official ncat user guide from the nmap project, covering use cases from simple port testing to full TLS proxying and connection brokering with detailed examples.
- [Beej's Guide to Network Programming](https://beej.us/guide/bgnet/) — The classic free guide explaining the BSD socket API underlying nc — essential for understanding why "connection refused" vs "connection timed out" behave differently and what they mean at the kernel level.
