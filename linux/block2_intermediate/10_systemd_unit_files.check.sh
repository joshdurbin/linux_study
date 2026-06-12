#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "unit_ssh.txt exists" "[[ -f ~/practice/unit_ssh.txt ]]"
check "unit_ssh.txt has ExecStart" "grep -qi 'ExecStart' ~/practice/unit_ssh.txt"

check "hello.service exists" "[[ -f ~/practice/hello.service ]]"
check "hello.service has Description" "grep -qi 'Description' ~/practice/hello.service"
check "hello.service has ExecStart" "grep -qi 'ExecStart' ~/practice/hello.service"
check "hello.service has Type=oneshot" "grep -qi 'oneshot' ~/practice/hello.service"
check "hello.service has WantedBy" "grep -qi 'WantedBy' ~/practice/hello.service"

check "unit_verify.txt exists" "[[ -f ~/practice/unit_verify.txt ]]"
check "unit_dropin.txt exists" "[[ -f ~/practice/unit_dropin.txt ]]"
check "unit_props.txt exists" "[[ -f ~/practice/unit_props.txt ]]"
check "unit_props.txt has ActiveState" "grep -qi 'ActiveState' ~/practice/unit_props.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
