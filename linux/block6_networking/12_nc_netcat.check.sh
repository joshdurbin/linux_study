#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "nc is installed"                  "command -v nc >/dev/null 2>&1"
check "nc_portscan.txt exists"           "[[ -f ~/practice/nc_portscan.txt ]]"
check "nc_portscan.txt has scan results" "grep -qiE '(succeeded|refused|open|Connection)' ~/practice/nc_portscan.txt"
check "nc_transfer.txt exists"           "[[ -f ~/practice/nc_transfer.txt ]]"
check "nc_transfer.txt has content"      "[[ -s ~/practice/nc_transfer.txt ]]"
check "nc_http.txt exists"               "[[ -f ~/practice/nc_http.txt ]]"
check "wait_for_port.sh exists"          "[[ -f ~/practice/wait_for_port.sh ]]"
check "wait_for_port.sh is executable"   "[[ -x ~/practice/wait_for_port.sh ]]"
check "wait_for_port.sh uses nc -z"      "grep -q 'nc -z' ~/practice/wait_for_port.sh"
check "wait_for_port.sh has timeout"     "grep -qE '(TIMEOUT|timeout|elapsed)' ~/practice/wait_for_port.sh"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
