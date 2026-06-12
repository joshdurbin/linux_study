#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "~/practice/strace_analysis.txt exists" "[[ -f ~/practice/strace_analysis.txt ]]"
check "strace_analysis.txt is non-empty" "[[ -s ~/practice/strace_analysis.txt ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
