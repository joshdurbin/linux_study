#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "mount_ns_notes.txt exists" "[[ -f ~/practice/mount_ns_notes.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/mount_ns_notes.txt ]]"
check "notes mention mount namespace" "grep -qi 'mount.*namespace\|namespace.*mount' ~/practice/mount_ns_notes.txt"
check "notes mention pivot_root or chroot" "grep -qiE 'pivot_root|chroot' ~/practice/mount_ns_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
