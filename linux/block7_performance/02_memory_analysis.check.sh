#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "~/practice/memory_analysis.txt exists" "[[ -f ~/practice/memory_analysis.txt ]]"
check "memory_analysis.txt is non-empty" "[[ -s ~/practice/memory_analysis.txt ]]"
check "memory_analysis.txt mentions MemAvailable" "grep -qi 'memavailable' ~/practice/memory_analysis.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
