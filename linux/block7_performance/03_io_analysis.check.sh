#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "~/practice/io_analysis.txt exists" "[[ -f ~/practice/io_analysis.txt ]]"
check "io_analysis.txt is non-empty" "[[ -s ~/practice/io_analysis.txt ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
