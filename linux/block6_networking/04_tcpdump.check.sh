#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: tcpdump is installed
check "tcpdump is installed" \
  "command -v tcpdump > /dev/null 2>&1"

# Check 2: practice directory exists
check "~/practice directory exists" \
  "[ -d \$HOME/practice ]"

# Check 3: capture.pcap or tcpdump_notes.txt exists
check "capture.pcap or tcpdump_notes.txt exists" \
  "[ -f \$HOME/practice/capture.pcap ] || [ -f \$HOME/practice/tcpdump_notes.txt ]"

# Check 4: if capture.pcap exists, it's a valid pcap file
check "capture.pcap is non-empty (if it exists)" \
  "[ ! -f \$HOME/practice/capture.pcap ] || [ -s \$HOME/practice/capture.pcap ]"

# Check 5: loopback interface exists for capturing
check "loopback interface exists" \
  "ip link show lo > /dev/null 2>&1"

# Check 6: tcpdump can list interfaces
check "tcpdump -D lists interfaces" \
  "sudo tcpdump -D > /dev/null 2>&1"

# Check 7: tcpdump can read a pcap if one exists
check "tcpdump can read capture.pcap (if it exists)" \
  "[ ! -f \$HOME/practice/capture.pcap ] || tcpdump -r \$HOME/practice/capture.pcap > /dev/null 2>&1"

# Check 8: tcpdump_notes.txt mentions tcpdump syntax (if it exists)
check "tcpdump_notes.txt contains useful content (if it exists)" \
  "[ ! -f \$HOME/practice/tcpdump_notes.txt ] || grep -qiE '(tcpdump|port|filter|pcap)' \$HOME/practice/tcpdump_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
