#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "postmortem_example.md exists" "[[ -f ~/practice/postmortem_example.md ]]"
check "postmortem is non-empty" "[[ -s ~/practice/postmortem_example.md ]]"
check "postmortem contains timeline" "grep -qi 'timeline' ~/practice/postmortem_example.md"
check "postmortem contains root cause" "grep -qi 'root.?cause' ~/practice/postmortem_example.md"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
