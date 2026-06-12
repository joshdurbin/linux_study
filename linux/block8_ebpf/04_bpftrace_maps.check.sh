#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "~/practice/bpftrace_maps.txt exists" "[[ -f ~/practice/bpftrace_maps.txt ]]"
check "bpftrace_maps.txt is non-empty" "[[ -s ~/practice/bpftrace_maps.txt ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
