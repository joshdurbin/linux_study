#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "cgroups_containers.txt exists" "[[ -f ~/practice/cgroups_containers.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/cgroups_containers.txt ]]"
check "notes mention cgroup" "grep -qi 'cgroup' ~/practice/cgroups_containers.txt"
check "notes mention memory or cpu limit" "grep -qiE 'memory\.max|cpu\.max|memory limit|cpu limit' ~/practice/cgroups_containers.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
