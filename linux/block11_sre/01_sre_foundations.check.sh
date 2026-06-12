#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "sre_foundations.txt exists" "[[ -f ~/practice/sre_foundations.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/sre_foundations.txt ]]"
check "notes mention SLO" "grep -q 'SLO' ~/practice/sre_foundations.txt"
check "notes mention error budget" "grep -qi 'error.?budget' ~/practice/sre_foundations.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
