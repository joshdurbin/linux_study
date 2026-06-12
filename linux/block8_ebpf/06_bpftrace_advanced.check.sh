#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "~/practice/bpftrace_advanced_notes.txt exists" "[[ -f ~/practice/bpftrace_advanced_notes.txt ]]"
check "bpftrace_advanced_notes.txt is non-empty" "[[ -s ~/practice/bpftrace_advanced_notes.txt ]]"
check "~/practice/bpftrace_advanced.bt exists" "[[ -f ~/practice/bpftrace_advanced.bt ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
