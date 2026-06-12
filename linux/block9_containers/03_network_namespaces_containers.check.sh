#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "container_net_notes.txt exists" "[[ -f ~/practice/container_net_notes.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/container_net_notes.txt ]]"
check "notes mention veth" "grep -qi 'veth' ~/practice/container_net_notes.txt"
check "notes mention namespace or bridge" "grep -qiE 'namespace|bridge|docker0' ~/practice/container_net_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
