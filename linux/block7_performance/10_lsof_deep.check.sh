#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "lsof_listeners.txt exists" "[[ -f ~/practice/lsof_listeners.txt ]]"
check "lsof_shell_fds.txt exists" "[[ -f ~/practice/lsof_shell_fds.txt ]]"
check "lsof_shell_fds.txt has PID" "grep -q 'PID' ~/practice/lsof_shell_fds.txt"
check "lsof_shell_fds.txt has FD count" "grep -qi 'Total FDs' ~/practice/lsof_shell_fds.txt"
check "lsof_logfile.txt exists" "[[ -f ~/practice/lsof_logfile.txt ]]"
check "lsof_deleted.txt exists" "[[ -f ~/practice/lsof_deleted.txt ]]"
check "lsof_limits.txt exists" "[[ -f ~/practice/lsof_limits.txt ]]"
check "lsof_limits.txt has open files or file-nr" "grep -qiE '(open files|[0-9]+\s+[0-9]+\s+[0-9]+)' ~/practice/lsof_limits.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
