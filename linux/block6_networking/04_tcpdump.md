# tcpdump: Packet Capture and Analysis

## What is tcpdump?

`tcpdump` is a command-line packet analyzer. It captures packets from a network interface and displays them in real time, or saves them to a `.pcap` file for later analysis with tools like Wireshark. It uses **BPF (Berkeley Packet Filter)** expressions to filter which packets to capture.

```bash
# Install if needed
sudo apt-get install -y tcpdump

# Must run as root (or with CAP_NET_ADMIN capability)
sudo tcpdump
```

## Basic Syntax

```bash
sudo tcpdump [options] [filter expression]
```

## Essential Options

| Option | Meaning |
|--------|---------|
| `-i eth0` | Capture on interface `eth0` |
| `-i any` | Capture on all interfaces |
| `-n` | Don't resolve hostnames (show IPs) |
| `-nn` | Don't resolve hostnames or port names |
| `-v` | Verbose: show TTL, IP options, checksums |
| `-vv` | More verbose |
| `-c 100` | Capture only 100 packets then exit |
| `-w file.pcap` | Write raw packets to file |
| `-r file.pcap` | Read from saved pcap file |
| `-A` | Print packet payload as ASCII |
| `-X` | Print payload in hex and ASCII |
| `-e` | Show ethernet (MAC) headers |
| `-s 0` | Capture full packet (no truncation) |

## BPF Filter Syntax

Filters go at the end of the command and are evaluated in the kernel — only matching packets are passed to tcpdump:

```bash
# By host
sudo tcpdump host 192.168.1.1
sudo tcpdump src 192.168.1.1       # only from this host
sudo tcpdump dst 8.8.8.8           # only to this host

# By port
sudo tcpdump port 80
sudo tcpdump port 53
sudo tcpdump dst port 443
sudo tcpdump src port 22

# By protocol
sudo tcpdump tcp
sudo tcpdump udp
sudo tcpdump icmp
sudo tcpdump arp

# Combining filters (and, or, not)
sudo tcpdump host 192.168.1.1 and port 80
sudo tcpdump tcp and not port 22
sudo tcpdump 'port 80 or port 443'

# Network-level filter
sudo tcpdump net 10.0.0.0/8
```

## Reading tcpdump Output

```
15:04:12.345678 IP 192.168.1.100.52341 > 93.184.216.34.80: Flags [S], seq 1234567890, win 65535, options [...], length 0
```

- `15:04:12.345678` — timestamp (microsecond precision)
- `IP` — IPv4 packet
- `192.168.1.100.52341` — source IP.port
- `93.184.216.34.80` — destination IP.port
- `Flags [S]` — TCP flags

### TCP Flag Codes

| Flag | Name | Meaning |
|------|------|---------|
| `[S]` | SYN | Connection request |
| `[S.]` | SYN-ACK | Connection accepted |
| `[.]` | ACK | Acknowledgment |
| `[P.]` | PSH-ACK | Data push |
| `[F.]` | FIN-ACK | Connection close |
| `[R]` | RST | Reset / reject |

A TCP handshake looks like:
```
Client → Server: [S]     (SYN)
Server → Client: [S.]    (SYN-ACK)
Client → Server: [.]     (ACK)
```

## Useful One-Liners

```bash
# Capture all traffic on loopback
sudo tcpdump -i lo -n

# Watch HTTP requests (non-TLS)
sudo tcpdump -i any -A -n 'tcp port 80'

# Capture DNS queries
sudo tcpdump -i any -n 'udp port 53'

# Capture ICMP (ping) traffic
sudo tcpdump -i any icmp

# Show only SYN packets (new connections)
sudo tcpdump -n 'tcp[tcpflags] & tcp-syn != 0'

# Capture and save to file (-s 0 = full packet)
sudo tcpdump -i eth0 -s 0 -w /tmp/capture.pcap

# Read back and analyze
tcpdump -r /tmp/capture.pcap -n

# Capture 50 packets then stop
sudo tcpdump -i any -c 50 -n

# Show traffic between two specific hosts
sudo tcpdump -n 'host 10.0.0.1 and host 10.0.0.2'
```

## Capturing HTTP Traffic

```bash
# In terminal 1: capture HTTP on loopback
sudo tcpdump -i lo -n -A 'tcp port 8080' &

# In terminal 2: start a simple HTTP server and make a request
python3 -m http.server 8080 &
curl -s http://127.0.0.1:8080/ > /dev/null

# See the HTTP GET request and response in the capture
```

## Writing and Reading pcap Files

pcap (`.pcap`) is the standard packet capture format, readable by Wireshark, tshark, and other tools:

```bash
# Capture 20 DNS packets to file
sudo tcpdump -i any -n -c 20 'udp port 53' -w ~/practice/dns_capture.pcap

# Read it back
tcpdump -r ~/practice/dns_capture.pcap -n

# Read with verbose output
tcpdump -r ~/practice/dns_capture.pcap -nn -v
```

## Further Reading

- [tcpdump man page](https://www.tcpdump.org/manpages/tcpdump.1.html) — The authoritative reference for every tcpdump option, output format, and timestamp type — the definitive source for the flags table in this lesson.
- [pcap-filter(7) BPF filter syntax](https://www.tcpdump.org/manpages/pcap-filter.7.html) — Complete documentation for all BPF primitives (`host`, `port`, `net`, `proto`), qualifiers, and boolean operators used in the filter examples throughout this lesson.
- [Wireshark User's Guide](https://www.wireshark.org/docs/wsug_html_chunked/) — Covers reading `.pcap` files captured by tcpdump in Wireshark's GUI, with a full chapter on display filters that complement tcpdump's BPF capture filters.
- [Daniel Stenberg: curl and HTTP internals](https://daniel.haxx.se/blog/) — The curl author's blog covers low-level TCP and HTTP details that become observable when reading tcpdump traces of curl sessions.
- [tcpdump source and documentation](https://github.com/the-tcpdump-group/tcpdump) — The source tree includes the BPF filter documentation and protocol dissectors, useful for understanding exactly what each filter expression matches at the byte level.
