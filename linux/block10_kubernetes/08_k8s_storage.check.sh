#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "storage_notes.txt exists" "[[ -f ~/practice/storage_notes.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/storage_notes.txt ]]"
check "notes mention PV or PVC" "grep -qiE '\bpv\b|\bpvc\b|persistentvolume' ~/practice/storage_notes.txt"
check "notes mention StorageClass or dynamic provisioning" "grep -qiE 'storageclass|dynamic.?provision' ~/practice/storage_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
