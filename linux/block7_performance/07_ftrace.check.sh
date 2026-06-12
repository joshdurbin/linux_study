#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "~/practice/ftrace_notes.txt exists" "[[ -f ~/practice/ftrace_notes.txt ]]"
check "ftrace_notes.txt is non-empty" "[[ -s ~/practice/ftrace_notes.txt ]]"
check "ftrace_notes.txt mentions /sys/kernel/debug/tracing" "grep -q '/sys/kernel/debug/tracing' ~/practice/ftrace_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
