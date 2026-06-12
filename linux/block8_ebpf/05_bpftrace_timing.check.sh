#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "~/practice/bpftrace_timing.txt exists" "[[ -f ~/practice/bpftrace_timing.txt ]]"
check "bpftrace_timing.txt is non-empty" "[[ -s ~/practice/bpftrace_timing.txt ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
