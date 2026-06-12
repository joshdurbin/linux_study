#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "~/practice/cpu_analysis.txt exists" "[[ -f ~/practice/cpu_analysis.txt ]]"
check "cpu_analysis.txt is non-empty" "[[ -s ~/practice/cpu_analysis.txt ]]"
check "cpu_analysis.txt contains load average output" "grep -qi 'load average' ~/practice/cpu_analysis.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
