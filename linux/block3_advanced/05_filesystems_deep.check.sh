#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "mounts_tree.txt exists"            "[[ -f ~/practice/mounts_tree.txt ]]"
check "mounts_tree.txt is non-empty"      "[[ -s ~/practice/mounts_tree.txt ]]"
check "fstab_copy.txt exists"             "[[ -f ~/practice/fstab_copy.txt ]]"
check "fstab_copy.txt has content"        "[[ -s ~/practice/fstab_copy.txt ]]"
check "tmpfs_test.txt exists"             "[[ -f ~/practice/tmpfs_test.txt ]]"
check "tmpfs_test.txt has tmpfs test data" "grep -q 'tmpfs test data' ~/practice/tmpfs_test.txt"
check "fstab_examples.txt exists"         "[[ -f ~/practice/fstab_examples.txt ]]"
check "fstab_examples.txt has UUID"       "grep -qi 'UUID' ~/practice/fstab_examples.txt"
check "fstab_examples.txt has tmpfs"      "grep -qi 'tmpfs' ~/practice/fstab_examples.txt"
check "fstab_examples.txt has bind"       "grep -qi 'bind' ~/practice/fstab_examples.txt"
check "fs_info.txt exists"                "[[ -f ~/practice/fs_info.txt ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
