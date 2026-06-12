#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "overlayfs_notes.txt exists" "[[ -f ~/practice/overlayfs_notes.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/overlayfs_notes.txt ]]"
check "notes contain lowerdir" "grep -q 'lowerdir' ~/practice/overlayfs_notes.txt"
check "notes contain overlay keyword" "grep -qiE 'overlay|overlayfs' ~/practice/overlayfs_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
