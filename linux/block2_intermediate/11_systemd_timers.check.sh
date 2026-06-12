#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "timers_list.txt exists" "[[ -f ~/practice/timers_list.txt ]]"
check "timers_list.txt has timer data" "grep -qiE '(timer|NEXT|LAST)' ~/practice/timers_list.txt"

check "timer_calendar.txt exists" "[[ -f ~/practice/timer_calendar.txt ]]"
check "timer_calendar.txt has calendar output" "grep -qiE '(Next elapse|Iteration|From now)' ~/practice/timer_calendar.txt"

check "cleanup.service exists" "[[ -f ~/practice/cleanup.service ]]"
check "cleanup.service has ExecStart" "grep -qi 'ExecStart' ~/practice/cleanup.service"
check "cleanup.service is oneshot" "grep -qi 'oneshot' ~/practice/cleanup.service"

check "cleanup.timer exists" "[[ -f ~/practice/cleanup.timer ]]"
check "cleanup.timer has OnCalendar" "grep -qi 'OnCalendar' ~/practice/cleanup.timer"
check "cleanup.timer has Persistent" "grep -qi 'Persistent' ~/practice/cleanup.timer"
check "cleanup.timer has WantedBy=timers.target" "grep -qi 'timers.target' ~/practice/cleanup.timer"

check "timer_apt_daily.txt exists" "[[ -f ~/practice/timer_apt_daily.txt ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
