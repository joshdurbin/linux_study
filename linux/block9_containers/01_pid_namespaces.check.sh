#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "pid_ns_notes.txt exists" "[[ -f ~/practice/pid_ns_notes.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/pid_ns_notes.txt ]]"
check "notes mention namespace" "grep -qi 'namespace' ~/practice/pid_ns_notes.txt"
check "notes mention PID 1 or init" "grep -qiE 'pid.?1|init' ~/practice/pid_ns_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
