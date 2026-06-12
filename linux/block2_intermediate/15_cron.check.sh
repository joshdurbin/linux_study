#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "cron_inventory.txt exists"                "[[ -f ~/practice/cron_inventory.txt ]]"
check "cron_inventory.txt has crontab content"   "grep -qiE '(cron|minute|hour|\*)' ~/practice/cron_inventory.txt"
check "cron_mine.txt exists"                     "[[ -f ~/practice/cron_mine.txt ]]"
check "cron_ran.txt exists"                      "[[ -f ~/practice/cron_ran.txt ]]"
check "cron_expressions.txt exists"              "[[ -f ~/practice/cron_expressions.txt ]]"
check "cron_expressions.txt has 5 entries"       "[[ $(grep -vc '^#\|^$' ~/practice/cron_expressions.txt 2>/dev/null) -ge 5 ]]"
check "cron_expressions.txt has @reboot"         "grep -q '@reboot' ~/practice/cron_expressions.txt"
check "cron_expressions.txt has */15"            "grep -qE '\*/15' ~/practice/cron_expressions.txt"
check "cron_env_job.txt exists"                  "[[ -f ~/practice/cron_env_job.txt ]]"
check "cron_env_job.txt mentions absolute paths" "grep -qi 'absolute' ~/practice/cron_env_job.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
