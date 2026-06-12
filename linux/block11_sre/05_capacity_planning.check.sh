#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "capacity_plan.txt exists" "[[ -f ~/practice/capacity_plan.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/capacity_plan.txt ]]"
check "notes mention req/s or requests per second" "grep -qiE 'req/s|requests.?per.?second|rps' ~/practice/capacity_plan.txt"
check "notes mention growth or headroom" "grep -qiE 'growth|headroom|capacity' ~/practice/capacity_plan.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
