#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "dmesg_recent.txt exists" "[[ -f ~/practice/dmesg_recent.txt ]]"
check "dmesg_recent.txt is non-empty" "[[ -s ~/practice/dmesg_recent.txt ]]"
check "dmesg_errors.txt exists" "[[ -f ~/practice/dmesg_errors.txt ]]"
check "dmesg_hw.txt exists" "[[ -f ~/practice/dmesg_hw.txt ]]"
check "dmesg_write.txt exists" "[[ -f ~/practice/dmesg_write.txt ]]"
check "journalctl_kernel.txt exists" "[[ -f ~/practice/journalctl_kernel.txt ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
