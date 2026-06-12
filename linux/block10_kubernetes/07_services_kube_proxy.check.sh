#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "services_notes.txt exists" "[[ -f ~/practice/services_notes.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/services_notes.txt ]]"
check "notes mention ClusterIP" "grep -qi 'clusterip' ~/practice/services_notes.txt"
check "notes mention iptables or IPVS" "grep -qiE 'iptables|ipvs' ~/practice/services_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
