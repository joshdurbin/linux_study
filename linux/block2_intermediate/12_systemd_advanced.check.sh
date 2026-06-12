#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "systemd_analyze.txt exists" "[[ -f ~/practice/systemd_analyze.txt ]]"
check "systemd_analyze.txt has content" "[[ -s ~/practice/systemd_analyze.txt ]]"

check "systemd_critical_chain.txt exists" "[[ -f ~/practice/systemd_critical_chain.txt ]]"
check "systemd_critical_chain.txt has content" "[[ -s ~/practice/systemd_critical_chain.txt ]]"

check "systemd_sockets.txt exists" "[[ -f ~/practice/systemd_sockets.txt ]]"

check "worker@.service exists" "[[ -f ~/practice/worker@.service ]]"
check "worker@.service has Description with %i" "grep -q '%i' ~/practice/worker@.service"
check "worker@.service has ExecStart" "grep -qi 'ExecStart' ~/practice/worker@.service"

check "journal_errors.txt exists" "[[ -f ~/practice/journal_errors.txt ]]"
check "journal_disk.txt exists" "[[ -f ~/practice/journal_disk.txt ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
