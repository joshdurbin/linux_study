#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "tshark installed" "command -v tshark >/dev/null 2>&1"
check "loopback.pcap exists" "[[ -f ~/practice/loopback.pcap ]]"
check "tshark_read.txt exists" "[[ -f ~/practice/tshark_read.txt ]]"
check "tshark_read.txt is non-empty" "[[ -s ~/practice/tshark_read.txt ]]"
check "dns_queries.txt exists" "[[ -f ~/practice/dns_queries.txt ]]"
check "tshark_protocols.txt exists" "[[ -f ~/practice/tshark_protocols.txt ]]"
check "tshark_filters.txt exists" "[[ -f ~/practice/tshark_filters.txt ]]"
check "tshark_filters.txt has 5+ lines" "[[ $(wc -l < ~/practice/tshark_filters.txt) -ge 5 ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
