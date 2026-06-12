# Exercise: tcpdump

## Setup

```bash
mkdir -p ~/practice
sudo apt-get install -y tcpdump 2>/dev/null || true
```

## Task 1: Basic Capture on Loopback

Start a background capture on loopback, generate traffic, then stop:

```bash
# Start capture in background (10 packets max)
sudo tcpdump -i lo -n -c 10 -w ~/practice/capture.pcap &
TCPDUMP_PID=$!

# Generate loopback traffic
ping -c 3 127.0.0.1 > /dev/null 2>&1

# Wait for tcpdump to finish
wait $TCPDUMP_PID 2>/dev/null || true

echo "Capture saved to ~/practice/capture.pcap"
ls -la ~/practice/capture.pcap
```

## Task 2: Read the Captured File

```bash
# Read the pcap file
tcpdump -r ~/practice/capture.pcap -n

# Read with verbose output
tcpdump -r ~/practice/capture.pcap -nn -v 2>/dev/null | head -20
```

Identify:
- Source and destination IPs
- Protocol (ICMP for ping)
- Packet types (echo request, echo reply)

## Task 3: Capture DNS Traffic

If DNS resolution is available:

```bash
# Capture DNS in background
sudo tcpdump -i any -n -c 5 'udp port 53' -w ~/practice/dns.pcap &
TCPDUMP_PID=$!

# Trigger DNS resolution
host google.com 2>/dev/null || nslookup google.com 2>/dev/null || \
  cat /etc/resolv.conf

sleep 2
kill $TCPDUMP_PID 2>/dev/null || true
wait $TCPDUMP_PID 2>/dev/null || true
```

If the capture got packets:
```bash
[ -s ~/practice/dns.pcap ] && tcpdump -r ~/practice/dns.pcap -n || echo "No DNS packets captured (may be offline)"
```

## Task 4: Capture HTTP Traffic on Loopback

```bash
# Start a simple HTTP server in background
python3 -m http.server 8765 &
HTTP_PID=$!
sleep 1

# Start capture in background
sudo tcpdump -i lo -n -A -c 20 'tcp port 8765' > ~/practice/http_capture.txt 2>&1 &
TCP_PID=$!

# Make an HTTP request
curl -s http://127.0.0.1:8765/ > /dev/null

sleep 2
kill $TCP_PID $HTTP_PID 2>/dev/null || true
wait 2>/dev/null

# View captured HTTP traffic
head -30 ~/practice/http_capture.txt
```

## Task 5: Practice Filter Expressions

Without actually capturing (just verify syntax), understand these filters:

```bash
# Show what a filter looks like when compiled
sudo tcpdump -i lo -n 'tcp and port 80' -d 2>/dev/null | head -5 || true

# Filters to know:
echo "Filter examples:"
echo "  host 1.2.3.4          - traffic to/from a host"
echo "  port 443              - traffic on port 443"
echo "  tcp and not port 22   - TCP traffic except SSH"
echo "  udp port 53           - DNS queries"
echo "  icmp                  - ping traffic"
```

## Task 6: Save tcpdump Notes

```bash
cat > ~/practice/tcpdump_notes.txt << 'EOF'
tcpdump Quick Reference
=======================
sudo tcpdump -i any -n           # all interfaces, no DNS
sudo tcpdump -i eth0 -c 100      # 100 packets from eth0
sudo tcpdump -w file.pcap        # save to file
tcpdump -r file.pcap             # read from file
sudo tcpdump host 1.2.3.4        # filter by host
sudo tcpdump port 80             # filter by port
sudo tcpdump tcp                 # filter by protocol
sudo tcpdump -A 'port 80'        # show ASCII payload

TCP Flags: [S]=SYN [S.]=SYN-ACK [.]=ACK [P.]=PSH [F.]=FIN [R]=RST
EOF
```

## Expected Outcome

- `~/practice/capture.pcap` OR `~/practice/tcpdump_notes.txt` exists
- You can capture packets with tcpdump and read pcap files
- You understand BPF filter syntax for hosts, ports, and protocols
