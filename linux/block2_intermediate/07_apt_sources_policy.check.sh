#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "apt_policy.txt exists"  "[[ -f ~/practice/apt_policy.txt ]]"
check "apt_policy.txt has version info" "grep -qiE '(installed|candidate|http)' ~/practice/apt_policy.txt"
check "apt_deps.txt exists" "[[ -f ~/practice/apt_deps.txt ]]"
check "apt_deps.txt is non-empty" "[[ -s ~/practice/apt_deps.txt ]]"
check "apt_hold.txt exists" "[[ -f ~/practice/apt_hold.txt ]]"
check "apt_hold.txt mentions hold" "grep -qi 'hold' ~/practice/apt_hold.txt"
check "apt_show.txt exists" "[[ -f ~/practice/apt_show.txt ]]"
check "apt_show.txt has Version field" "grep -qi 'version' ~/practice/apt_show.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
