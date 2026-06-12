#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "user_ns_notes.txt exists" "[[ -f ~/practice/user_ns_notes.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/user_ns_notes.txt ]]"
check "notes mention UID mapping" "grep -qiE 'uid.*map|map.*uid|uid_map' ~/practice/user_ns_notes.txt"
check "notes mention rootless or user namespace" "grep -qiE 'rootless|user.?namespace' ~/practice/user_ns_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
