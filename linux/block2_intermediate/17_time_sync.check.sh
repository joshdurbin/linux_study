#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "time_status.txt exists"               "[[ -f ~/practice/time_status.txt ]]"
check "time_status.txt has timedatectl info" "grep -qiE '(Local time|Universal time|NTP)' ~/practice/time_status.txt"
check "time_ntp.txt exists"                  "[[ -f ~/practice/time_ntp.txt ]]"
check "time_ntp.txt is non-empty"            "[[ -s ~/practice/time_ntp.txt ]]"
check "time_tz_test.txt exists"              "[[ -f ~/practice/time_tz_test.txt ]]"
check "time_tz_test.txt shows UTC was set"   "grep -qi 'UTC' ~/practice/time_tz_test.txt"
check "chrony_config_example.conf exists"    "[[ -f ~/practice/chrony_config_example.conf ]]"
check "chrony config has pool entry"         "grep -q 'pool' ~/practice/chrony_config_example.conf"
check "chrony config has allow entry"        "grep -q 'allow' ~/practice/chrony_config_example.conf"
check "chrony config has makestep"           "grep -q 'makestep' ~/practice/chrony_config_example.conf"
check "chrony config has driftfile"          "grep -q 'driftfile' ~/practice/chrony_config_example.conf"
check "ntp_concepts.txt exists"              "[[ -f ~/practice/ntp_concepts.txt ]]"
check "ntp_concepts.txt mentions stratum"    "grep -qi 'stratum' ~/practice/ntp_concepts.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
