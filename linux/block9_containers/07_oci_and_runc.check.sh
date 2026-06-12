#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "oci_notes.txt exists" "[[ -f ~/practice/oci_notes.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/oci_notes.txt ]]"
check "notes contain config.json" "grep -q 'config.json' ~/practice/oci_notes.txt"
check "notes contain runc" "grep -qi 'runc' ~/practice/oci_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
