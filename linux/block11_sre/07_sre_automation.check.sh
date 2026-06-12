#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "automation_plan.txt exists" "[[ -f ~/practice/automation_plan.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/automation_plan.txt ]]"
check "notes mention toil or automation" "grep -qiE 'toil|automat' ~/practice/automation_plan.txt"
check "notes describe a specific task or plan" "grep -qiE 'deploy|cron|pipeline|ansible|terraform' ~/practice/automation_plan.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
