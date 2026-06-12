#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "pin_policy_before.txt exists" "[[ -f ~/practice/pin_policy_before.txt ]]"
check "pin_policy_before.txt has priority info" "grep -qE '[0-9]{3}' ~/practice/pin_policy_before.txt"
check "study.pref was created" "[[ -f /etc/apt/preferences.d/study.pref ]]"
check "study.pref contains snapd pin" "grep -q 'snapd' /etc/apt/preferences.d/study.pref"
check "study.pref has negative priority" "grep -qE 'Pin-Priority:.*-1' /etc/apt/preferences.d/study.pref"
check "pin_snapd_policy.txt exists" "[[ -f ~/practice/pin_snapd_policy.txt ]]"
check "pin_example.pref exists" "[[ -f ~/practice/pin_example.pref ]]"
check "pin_example.pref has nginx pin" "grep -q 'nginx' ~/practice/pin_example.pref"
check "pin_example.pref has version pin" "grep -qE 'Pin:.*version' ~/practice/pin_example.pref"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
