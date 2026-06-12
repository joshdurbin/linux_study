#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "fd_table.txt exists"               "[[ -f ~/practice/fd_table.txt ]]"
check "fd_table.txt lists FD 0"           "grep -q 'FD 0' ~/practice/fd_table.txt"
check "fd_table.txt lists FD 1"           "grep -q 'FD 1' ~/practice/fd_table.txt"
check "fd_info.txt exists"                "[[ -f ~/practice/fd_info.txt ]]"
check "fd_info.txt has pos or flags"      "grep -qE '(pos|flags)' ~/practice/fd_info.txt"
check "fd_strace.txt exists"              "[[ -f ~/practice/fd_strace.txt ]]"
check "fd_inherit.txt exists"             "[[ -f ~/practice/fd_inherit.txt ]]"
check "fd_inherit.txt has written text"   "grep -q 'written via FD' ~/practice/fd_inherit.txt"
check "fd_limits.txt exists"              "[[ -f ~/practice/fd_limits.txt ]]"
check "fd_limits.txt has soft limit"      "grep -qi 'soft' ~/practice/fd_limits.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
