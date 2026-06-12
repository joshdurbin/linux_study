# socat — Bidirectional Data Relay

socat (SOcket CAT) creates connections between two bidirectional data streams. Think of it as `nc` with support for TLS, Unix sockets, PTYs, files, and complex addressing — the tool you reach for when netcat isn't expressive enough.

## Basic Syntax

```
socat [options] <address1> <address2>
```

socat relays data in both directions between the two addresses.

## Address Types

```
TCP:<host>:<port>             TCP connection to host:port
TCP-LISTEN:<port>             TCP listener on port
UDP:<host>:<port>             UDP
UNIX-CONNECT:<path>           Unix domain socket client
UNIX-LISTEN:<path>            Unix domain socket server
STDIO  or  -                  standard input/output
EXEC:<cmd>                    run a command, use its stdio
PTY                           allocate a pseudo-terminal
FILE:<path>                   open a file
SSL:<host>:<port>             TLS client
SSL-LISTEN:<port>             TLS server (needs cert/key)
```

## Common One-Liners

```bash
# TCP relay: forward local port 8080 to remote host
socat TCP-LISTEN:8080,fork TCP:backend.internal:80

# Simple netcat-style listener (one connection)
socat - TCP-LISTEN:4444

# Send a file over TCP
socat TCP-LISTEN:9000 FILE:data.tar.gz          # receiver
socat FILE:data.tar.gz TCP:receiver:9000        # sender

# Connect to a Unix domain socket (Docker, Postgres, etc.)
socat - UNIX-CONNECT:/var/run/docker.sock

# Expose a Unix socket as a TCP port (useful for remote access)
socat TCP-LISTEN:2375,fork,reuseaddr UNIX-CONNECT:/var/run/docker.sock

# Bidirectional pipe between two commands
socat EXEC:'bash -i',pty,setsid,ctty STDIO

# Port scan a range (one port at a time)
for p in 22 80 443 8080; do
  socat /dev/null TCP:target:$p,connect-timeout=1 2>/dev/null && echo "$p open"
done
```

## TLS / SSL

```bash
# Generate a self-signed cert for testing
openssl req -newkey rsa:2048 -nodes -keyout server.key -x509 -days 365 -out server.crt

# TLS server: serve stdin/stdout over TLS
socat SSL-LISTEN:4433,cert=server.crt,key=server.key,verify=0 STDIO

# TLS client
socat - SSL:localhost:4433,verify=0

# TLS proxy: wrap a plain TCP service in TLS
socat SSL-LISTEN:8443,cert=server.crt,key=server.key,fork,verify=0 TCP:localhost:8080
```

## PTY — Pseudo-Terminal

Useful when a program requires a TTY but you're piping:

```bash
# Create a PTY-backed socat relay
socat PTY,raw,echo=0,link=/tmp/vmodem EXEC:'ssh user@remote',pty,setsid,ctty
```

## Key Options

| Option | Meaning |
|--------|---------|
| `fork` | Handle multiple connections (fork per connection) |
| `reuseaddr` | Allow reuse of the port immediately after close |
| `verify=0` | Skip TLS certificate verification |
| `connect-timeout=N` | Timeout in seconds |
| `-d -d` | Increase debug verbosity (add more `-d` for more output) |
| `crnl` | Convert CR+LF (useful for serial/telnet) |

## Compared to nc / ncat

| Feature | nc | socat |
|---------|----|----|
| TLS/SSL | ncat only | Yes |
| Unix sockets | No | Yes |
| PTY allocation | No | Yes |
| Fork (multiple clients) | ncat only | Yes |
| File transfer | Yes | Yes |
| UDP | Yes | Yes |

## Further Reading

- [socat man page](https://linux.die.net/man/1/socat) — The complete socat manual covering all address types (`TCP`, `SSL`, `UNIX`, `PTY`, `EXEC`), options (`fork`, `reuseaddr`, `verify`), and the bidirectional relay model described in this lesson.
- [socat examples collection](http://www.dest-unreach.org/socat/doc/socat.html) — The official socat documentation with extensive real-world examples including TLS proxying, PTY allocation, and UNIX socket bridging patterns.
- [socket(2) man page](https://man7.org/linux/man-pages/man2/socket.2.html) — Documents the socket creation syscall underlying all socat address types, explaining the `domain`, `type`, and `protocol` parameters that map to socat's TCP/UDP/UNIX address families.
- [unix(7) man page](https://man7.org/linux/man-pages/man7/unix.7.html) — Documents Unix domain socket semantics and `SO_PEERCRED` credential passing that socat's `UNIX-CONNECT` and `UNIX-LISTEN` address types rely on for inter-process communication.
