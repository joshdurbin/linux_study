#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "nmap is installed"                  "command -v nmap >/dev/null 2>&1"
check "nmap_localhost.txt exists"          "[[ -f ~/practice/nmap_localhost.txt ]]"
check "nmap_localhost.txt has nmap header" "grep -qi 'nmap scan report' ~/practice/nmap_localhost.txt"
check "nmap_version.txt exists"            "[[ -f ~/practice/nmap_version.txt ]]"
check "nmap_top100.gnmap exists"           "[[ -f ~/practice/nmap_top100.gnmap ]]"
check "nmap_scripts.txt exists"            "[[ -f ~/practice/nmap_scripts.txt ]]"
check "nmap_cheatsheet.txt exists"         "[[ -f ~/practice/nmap_cheatsheet.txt ]]"
check "cheatsheet has port states"         "grep -qiE '(filtered|closed|open)' ~/practice/nmap_cheatsheet.txt"
check "cheatsheet has timing info"         "grep -qE '(-T[0-9]|timing|aggressive)' ~/practice/nmap_cheatsheet.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
