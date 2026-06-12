#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "scheduler_notes.txt exists" "[[ -f ~/practice/scheduler_notes.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/scheduler_notes.txt ]]"
check "notes mention filter phase" "grep -qi 'filter' ~/practice/scheduler_notes.txt"
check "notes mention score phase" "grep -qi 'score' ~/practice/scheduler_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
