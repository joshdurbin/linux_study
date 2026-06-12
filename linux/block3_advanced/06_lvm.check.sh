#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "lvm_inventory.txt exists"              "[[ -f ~/practice/lvm_inventory.txt ]]"
check "lvm_inventory.txt is non-empty"        "[[ -s ~/practice/lvm_inventory.txt ]]"
check "lvm_root.txt exists"                   "[[ -f ~/practice/lvm_root.txt ]]"
check "lvm_workflow.txt exists"               "[[ -f ~/practice/lvm_workflow.txt ]]"
check "lvm_workflow.txt has pvcreate"         "grep -q 'pvcreate' ~/practice/lvm_workflow.txt"
check "lvm_workflow.txt has vgcreate"         "grep -q 'vgcreate' ~/practice/lvm_workflow.txt"
check "lvm_workflow.txt has lvcreate"         "grep -q 'lvcreate' ~/practice/lvm_workflow.txt"
check "lvm_workflow.txt has mkfs"             "grep -q 'mkfs' ~/practice/lvm_workflow.txt"
check "lvm_extend.txt exists"                 "[[ -f ~/practice/lvm_extend.txt ]]"
check "lvm_extend.txt has lvextend"           "grep -q 'lvextend' ~/practice/lvm_extend.txt"
check "lvm_extend.txt has resize2fs or xfs_growfs" "grep -qE '(resize2fs|xfs_growfs)' ~/practice/lvm_extend.txt"
check "lvm_snapshot.txt exists"               "[[ -f ~/practice/lvm_snapshot.txt ]]"
check "lvm_snapshot.txt mentions snapshot"    "grep -qi 'snapshot' ~/practice/lvm_snapshot.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
