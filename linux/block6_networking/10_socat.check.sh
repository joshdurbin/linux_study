#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "socat installed" "command -v socat >/dev/null 2>&1"
check "socat_version.txt exists" "[[ -f ~/practice/socat_version.txt ]]"
check "socat_version.txt has version info" "grep -qiE 'socat|version' ~/practice/socat_version.txt"
check "socat_echo.txt exists" "[[ -f ~/practice/socat_echo.txt ]]"
check "socat_docker_proxy.txt exists" "[[ -f ~/practice/socat_docker_proxy.txt ]]"
check "socat_transfer.txt exists" "[[ -f ~/practice/socat_transfer.txt ]]"
check "socat_cheatsheet.txt exists" "[[ -f ~/practice/socat_cheatsheet.txt ]]"
check "socat_cheatsheet.txt has 3+ lines" "[[ $(wc -l < ~/practice/socat_cheatsheet.txt) -ge 3 ]]"
check "socat_cheatsheet.txt mentions TCP" "grep -qi 'TCP' ~/practice/socat_cheatsheet.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
