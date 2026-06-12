# Exercise: tshark and Packet Analysis

## Tasks

1. **Install and capture**: Install tshark (`sudo apt-get install -y tshark`). Capture 20 packets on the loopback interface:
   ```bash
   sudo tshark -i lo -c 20 -w ~/practice/loopback.pcap
   # Generate traffic in another terminal: curl http://localhost 2>/dev/null || ping -c 5 127.0.0.1
   ```
   Save the capture to `~/practice/loopback.pcap`.

2. **Read and filter**: Read the PCAP and apply display filters:
   ```bash
   tshark -r ~/practice/loopback.pcap
   ```
   Save the full output to `~/practice/tshark_read.txt`.

3. **DNS queries**: Capture DNS traffic for 10 seconds while making DNS lookups:
   ```bash
   (sleep 2 && dig google.com @8.8.8.8 +short && dig github.com @8.8.8.8 +short) &
   sudo tshark -i eth0 -f "udp port 53" -c 10 -w ~/practice/dns.pcap 2>/dev/null \
     || sudo tshark -i any -f "udp port 53" -c 10 -w ~/practice/dns.pcap
   ```
   Extract DNS query names: `tshark -r ~/practice/dns.pcap -T fields -e dns.qry.name 2>/dev/null`
   Save results to `~/practice/dns_queries.txt`.

4. **Protocol statistics**: Run `tshark -r ~/practice/loopback.pcap -q -z io,phs` and save the protocol hierarchy to `~/practice/tshark_protocols.txt`.

5. **Write filter cheatsheet**: Document 5 tshark display filters (with explanations) in `~/practice/tshark_filters.txt`.

## Hints

- Use `-i lo` for loopback (always available), `-i eth0` or `-i any` for external traffic
- If capture fails due to permissions, run with `sudo`
- Display filters use Wireshark syntax: `http.request`, `dns.qry.name`, `tcp.flags.syn`; capture filters use BPF: `port 53`, `host x.x.x.x`
