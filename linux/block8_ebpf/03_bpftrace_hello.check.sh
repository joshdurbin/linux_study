#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "~/practice/bpftrace_hello.txt exists" "[[ -f ~/practice/bpftrace_hello.txt ]]"
check "bpftrace_hello.txt is non-empty" "[[ -s ~/practice/bpftrace_hello.txt ]]"
check "bpftrace_hello.txt mentions 'bpftrace'" "grep -qi 'bpftrace' ~/practice/bpftrace_hello.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
