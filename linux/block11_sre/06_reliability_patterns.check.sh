#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "reliability_patterns.txt exists" "[[ -f ~/practice/reliability_patterns.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/reliability_patterns.txt ]]"
check "notes mention circuit breaker" "grep -qi 'circuit.?breaker' ~/practice/reliability_patterns.txt"
check "notes mention retry or backoff" "grep -qiE 'retry|backoff' ~/practice/reliability_patterns.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
