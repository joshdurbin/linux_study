#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "cni_notes.txt exists" "[[ -f ~/practice/cni_notes.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/cni_notes.txt ]]"
check "notes contain CNI" "grep -q 'CNI' ~/practice/cni_notes.txt"
check "notes mention veth or pod CIDR" "grep -qiE 'veth|pod.?cidr|pod cidr' ~/practice/cni_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
