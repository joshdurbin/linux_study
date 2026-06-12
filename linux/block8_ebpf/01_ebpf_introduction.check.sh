#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "~/practice/ebpf_intro.txt exists" "[[ -f ~/practice/ebpf_intro.txt ]]"
check "ebpf_intro.txt is non-empty" "[[ -s ~/practice/ebpf_intro.txt ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
