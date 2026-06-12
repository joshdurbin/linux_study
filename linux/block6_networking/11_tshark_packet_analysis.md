# tshark and Packet Analysis

tshark is Wireshark's command-line interface — it understands 3000+ protocols and can dissect packets at layer 7, making it far more powerful than tcpdump for protocol analysis.

## tshark vs tcpdump

| Feature | tcpdump | tshark |
|---------|---------|--------|
| Protocol dissection | TCP/UDP/IP only | 3000+ protocols |
| Filter syntax | BPF (capture only) | BPF + display filters |
| Output formats | hex/ASCII/one-liner | JSON, PDML, CSV, hex |
| Field extraction | Limited | `-e field.name` |
| Follow streams | No | Yes (`-z follow,tcp`) |
| Decode as | No | `--decode-as` |

## Installation

```bash
sudo apt-get install -y tshark
# On first run it asks about capture permissions — choose "Yes"
```

## Basic Capture

```bash
# Live capture on interface eth0 (needs root or cap_net_raw)
sudo tshark -i eth0

# Capture to file, stop after 100 packets
sudo tshark -i eth0 -c 100 -w /tmp/capture.pcap

# Read a saved PCAP file
tshark -r /tmp/capture.pcap

# Quiet output (one line per packet, no header)
tshark -r capture.pcap -q
```

## Capture Filters (BPF — same as tcpdump)

Applied at kernel level — packets not matching are never captured:

```bash
sudo tshark -i eth0 -f "tcp port 443"
sudo tshark -i eth0 -f "host 192.168.1.1 and not port 22"
sudo tshark -i eth0 -f "udp port 53"
```

## Display Filters (Wireshark syntax — applied after capture)

Much richer — applied to already-captured data:

```bash
tshark -r capture.pcap -Y "http.request"
tshark -r capture.pcap -Y "dns.qry.name contains google"
tshark -r capture.pcap -Y "tcp.analysis.retransmission"
tshark -r capture.pcap -Y "ip.addr == 10.0.0.1"
tshark -r capture.pcap -Y "tcp.flags.syn == 1 && tcp.flags.ack == 0"  # SYN only
tshark -r capture.pcap -Y "http.response.code >= 400"  # HTTP errors
```

## Field Extraction with `-T fields -e`

```bash
# Extract HTTP request URLs
tshark -r capture.pcap -Y "http.request" -T fields \
  -e http.host -e http.request.uri

# Extract DNS queries
tshark -r capture.pcap -Y "dns.flags.response == 0" \
  -T fields -e frame.time -e ip.src -e dns.qry.name

# Extract TLS SNI (server name)
tshark -r capture.pcap -Y "tls.handshake.extensions_server_name" \
  -T fields -e ip.dst -e tls.handshake.extensions_server_name

# TCP connection summary: src, dst, port, bytes
tshark -r capture.pcap -q -z conv,tcp
```

## Following Streams

```bash
# Follow TCP stream 0 as ASCII
tshark -r capture.pcap -q -z follow,tcp,ascii,0

# Follow HTTP stream
tshark -r capture.pcap -q -z follow,http,ascii,0
```

## Useful One-Liners

```bash
# Top talkers by IP
tshark -r capture.pcap -q -z ip_hosts,tree

# HTTP requests in real time
sudo tshark -i eth0 -Y "http.request" -T fields \
  -e ip.src -e http.host -e http.request.method -e http.request.uri

# Detect port scans (many SYN to different ports)
sudo tshark -i eth0 -Y "tcp.flags.syn==1 && tcp.flags.ack==0" \
  -T fields -e ip.src -e tcp.dstport

# Count packets by protocol
tshark -r capture.pcap -q -z io,phs
```

## Decode Encrypted Protocols

```bash
# Decrypt TLS if you have the pre-master secret log
tshark -r tls.pcap -o "tls.keylog_file:/tmp/keylog.txt" \
  -Y "http2" -T fields -e http2.header.value
```

## Further Reading

- [tshark man page](https://www.wireshark.org/docs/man-pages/tshark.html) — Complete reference for all tshark options including `-Y` display filters, `-T fields -e` field extraction, `-z` statistics, and the `-f` capture filter syntax used throughout this lesson.
- [Wireshark display filter reference](https://www.wireshark.org/docs/dfref/) — Searchable index of every display filter field (`http.request`, `dns.qry.name`, `tcp.analysis.retransmission`) used in the `-Y` filter examples in this lesson.
- [pcap-filter(7) BPF syntax](https://www.tcpdump.org/manpages/pcap-filter.7.html) — Documents all BPF primitives shared between tcpdump and tshark's `-f` capture filters, including TCP flag bit-masking expressions.
- [Wireshark User's Guide: Statistics](https://www.wireshark.org/docs/wsug_html_chunked/ChStatistics.html) — Covers the `tshark -z` statistics modes (`conv,tcp`, `ip_hosts,tree`, `io,phs`) used in the one-liner examples for identifying top talkers and protocol distributions.
