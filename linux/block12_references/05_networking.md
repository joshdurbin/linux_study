# Networking References

Five resources that go deeper than this course's block6. Together they cover the full Linux networking stack from kernel internals to packet capture analysis to active reconnaissance.

---

## iproute2-cheatsheet
**Repo:** https://github.com/dmbaturin/iproute2-cheatsheet

The most complete practical reference for `ip`, `tc`, and `bridge` commands. Where block6 teaches the common cases, this cheatsheet covers the full command surface.

### Sections This Course Didn't Cover

**Traffic Control (`tc`)** — rate limiting, shaping, and queuing:
```bash
# Check current qdisc on an interface
tc qdisc show dev eth0

# Add a simple rate limit (token bucket)
sudo tc qdisc add dev eth0 root tbf rate 100mbit burst 32kbit latency 400ms

# fq_codel — fair queuing with controlled delay (default on many systems)
tc qdisc show dev eth0    # look for "fq_codel" or "pfifo_fast"

# Remove all tc rules
sudo tc qdisc del dev eth0 root
```

**Bridge management:**
```bash
bridge link show          # show bridge-attached ports
bridge fdb show           # MAC forwarding table (like ARP but for L2)
bridge vlan show          # VLAN assignments per port
```

**Neighbor table (ARP):**
```bash
ip neigh show             # ARP cache
ip neigh flush dev eth0   # clear ARP cache for an interface
ip neigh add 192.168.1.1 lladdr aa:bb:cc:dd:ee:ff dev eth0 nud permanent
```

**Advanced routing — policy routing:**
```bash
# Multiple routing tables (block6/02 touched this)
ip rule show              # policy routing rules (priority order)
ip route show table all   # all routing tables

# Add a rule: traffic from 10.0.0.2 uses table 100
ip rule add from 10.0.0.2 table 100
ip route add default via 192.168.1.1 table 100
```

---

## linux-netns-handbook
**Repo:** https://github.com/RatulSaqibKhan/linux-netns-handbook

Comprehensive hands-on guide to network namespaces. Block6/03 and block9/03 cover the basics; this handbook goes into multi-namespace topologies used in real container platforms.

### Lab Topologies to Build

These extend the veth-pair and bridge work from block6/03:

**Multi-tier network (simulating app + db in separate namespaces):**
```bash
# Create namespaces
ip netns add frontend
ip netns add backend
ip netns add db

# Create veth pairs and connect
ip link add veth-fe-br type veth peer name veth-br-fe
ip link add veth-be-br type veth peer name veth-br-be

# Bridge connecting all three (like docker0)
ip link add br0 type bridge
ip link set br0 up

# Move interfaces into namespaces
ip link set veth-fe-br netns frontend
ip link set veth-be-br netns backend

# Add veth bridge-sides to the bridge
ip link set veth-br-fe master br0
ip link set veth-br-be master br0
ip link set veth-br-fe up
ip link set veth-br-be up
```

**Simulating NAT (like Docker's masquerade):**
```bash
# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Masquerade all traffic from the 172.20.0.0/16 range
iptables -t nat -A POSTROUTING -s 172.20.0.0/16 -j MASQUERADE
```

---

## netshoot
**Repo:** https://github.com/nicolaka/netshoot

A Docker container packed with every networking diagnostic tool. Less a curriculum, more a curated toolkit and reference for what to run when debugging network issues.

### The Toolkit

```bash
# Run netshoot in the same network namespace as a container
docker run -it --net container:<container_name> nicolaka/netshoot

# Or in the host network namespace
docker run -it --net host nicolaka/netshoot

# Tools available (that aren't installed in the study container):
# mtr        — continuous traceroute with packet loss and latency per hop
# iperf3     — bandwidth measurement between two endpoints
# iftop      — bandwidth by connection (like top for network)
# ngrep      — network grep — filter packets by payload content
# nsenter    — enter container namespaces (already covered in block5/09)
# netstat    — legacy socket stats (use ss instead)
# arp-scan   — ARP-based host discovery
# httpie     — human-friendly HTTP client (like curl but readable)
```

### Debugging Patterns from netshoot

```bash
# Is the packet reaching the container at all?
tcpdump -i eth0 'host 10.0.0.5'        # inside the container netns

# Is DNS working inside this network namespace?
dig @8.8.8.8 google.com               # bypass /etc/resolv.conf
cat /etc/resolv.conf                   # what resolver is configured?

# Bandwidth test between two pods/containers
# Terminal 1 (receiver):
iperf3 -s
# Terminal 2 (sender):
iperf3 -c <receiver-ip> -t 10

# MTU issues (often cause mysterious packet drops)
ping -M do -s 1472 10.0.0.1           # send max-sized ping without fragmentation
# If this fails but ping -s 100 works: MTU mismatch
```

---

## tcpdump
**Repo:** https://github.com/the-tcpdump-group/tcpdump

The source and the definitive reference for BPF filter syntax. Block6/04 covers the common cases; the manpage and source are the authority on filter expressions.

### BPF Filter Syntax Not Covered in Block6

```bash
# Filter by TCP flags
tcpdump 'tcp[tcpflags] & (tcp-syn) != 0'         # all SYN packets
tcpdump 'tcp[tcpflags] & (tcp-syn|tcp-ack) == tcp-syn'  # SYN only, not SYN-ACK
tcpdump 'tcp[tcpflags] & (tcp-rst) != 0'         # RST packets (connection resets)
tcpdump 'tcp[tcpflags] & (tcp-fin) != 0'         # FIN packets (connection teardown)

# Filter by TCP window size (detect zero-window conditions)
tcpdump 'tcp[14:2] == 0'    # TCP window = 0 (receiver telling sender to stop)

# Filter ICMP types
tcpdump 'icmp[icmptype] = icmp-echo'     # ping requests only
tcpdump 'icmp[icmptype] = icmp-echoreply'  # ping replies

# Filter by DNS query type (position within UDP payload)
tcpdump -i eth0 'udp port 53 and udp[10] & 0x80 = 0'  # DNS queries only

# Capture and display application-layer content
tcpdump -A 'tcp port 80 and (tcp[tcpflags] & tcp-push != 0)'  # HTTP data segments
```

### Reading pcap Files Offline

```bash
# Save capture for offline analysis
tcpdump -i eth0 -w /tmp/capture.pcap

# Read it back (on any machine with tcpdump or Wireshark)
tcpdump -r /tmp/capture.pcap
tcpdump -r /tmp/capture.pcap 'tcp port 443'    # filter during read

# Summary statistics
tcpdump -r /tmp/capture.pcap -q | awk '{print $3}' | sort | uniq -c | sort -rn | head -20
```

---

## nmap
**Repo:** https://github.com/nmap/nmap

Block6/13 covers nmap fundamentals. The nmap scripting engine (NSE) is a full vulnerability/service-discovery platform that goes far beyond basic port scanning.

### NSE Scripts Relevant to SRE Work

```bash
# Service version and OS detection (not just port open/closed)
nmap -sV -O target

# SSL/TLS certificate inspection
nmap --script ssl-cert target -p 443
nmap --script ssl-enum-ciphers target -p 443    # cipher suite audit

# HTTP service discovery
nmap --script http-title target                 # grab page titles
nmap --script http-headers target               # show HTTP headers
nmap --script http-methods target               # which HTTP methods are allowed

# DNS zone transfer attempt (misconfiguration check)
nmap --script dns-zone-transfer --script-args dns-zone-transfer.domain=example.com -p 53 ns1.example.com

# Check for open SMTP relay (common misconfiguration)
nmap --script smtp-open-relay target -p 25

# Database discovery
nmap --script mysql-info target -p 3306
nmap --script redis-info target -p 6379
```

### The nmap Output Formats

```bash
# Save in all formats simultaneously
nmap -oA /tmp/scan_results target
# Creates: scan_results.nmap (text), scan_results.xml, scan_results.gnmap (greppable)

# Parse the greppable format
grep "open" /tmp/scan_results.gnmap | awk '{print $2, $5}'

# Parse the XML format with xsltproc
xsltproc /usr/share/nmap/nmap.xsl /tmp/scan_results.xml > /tmp/scan_results.html
```
