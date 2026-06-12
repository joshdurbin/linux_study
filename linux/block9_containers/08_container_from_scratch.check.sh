#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "container_scratch.txt exists" "[[ -f ~/practice/container_scratch.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/container_scratch.txt ]]"
check "notes mention namespace" "grep -qi 'namespace' ~/practice/container_scratch.txt"
check "notes mention cgroup or proc" "grep -qiE 'cgroup|/proc' ~/practice/container_scratch.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
