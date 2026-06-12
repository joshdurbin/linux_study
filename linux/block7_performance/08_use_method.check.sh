#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "~/practice/use_method_output.txt exists" "[[ -f ~/practice/use_method_output.txt ]]"
check "use_method_output.txt is non-empty" "[[ -s ~/practice/use_method_output.txt ]]"
check "use_method_output.txt contains 'load average' or 'uptime'" \
    "grep -qiE 'load average|uptime' ~/practice/use_method_output.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
