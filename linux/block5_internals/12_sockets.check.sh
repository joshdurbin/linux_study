#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "socket_inventory.txt exists"          "[[ -f ~/practice/socket_inventory.txt ]]"
check "socket_inventory.txt is non-empty"    "[[ -s ~/practice/socket_inventory.txt ]]"
check "proc_net_sockets.txt exists"          "[[ -f ~/practice/proc_net_sockets.txt ]]"
check "proc_net_sockets.txt has TCP section" "grep -q 'TCP' ~/practice/proc_net_sockets.txt"
check "unix_socket_test.txt exists"          "[[ -f ~/practice/unix_socket_test.txt ]]"
check "socket_strace.txt exists"             "[[ -f ~/practice/socket_strace.txt ]]"
check "socket_options.txt exists"            "[[ -f ~/practice/socket_options.txt ]]"
check "socket_options.txt has 5+ lines"      "[[ $(wc -l < ~/practice/socket_options.txt) -ge 5 ]]"
check "socket_options.txt mentions REUSEADDR or KEEPALIVE" \
  "grep -qiE '(REUSEADDR|KEEPALIVE|NODELAY)' ~/practice/socket_options.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
