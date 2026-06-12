#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "etcd_notes.txt exists" "[[ -f ~/practice/etcd_notes.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/etcd_notes.txt ]]"
check "notes contain Raft or quorum" "grep -qiE 'raft|quorum' ~/practice/etcd_notes.txt"
check "notes mention etcd" "grep -qi 'etcd' ~/practice/etcd_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
