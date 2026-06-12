#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "logrotate_inventory.txt exists"          "[[ -f ~/practice/logrotate_inventory.txt ]]"
check "logrotate_inventory.txt has config info" "grep -qiE '(rotate|compress|weekly|daily)' ~/practice/logrotate_inventory.txt"
check "logrotate_dryrun.txt exists"             "[[ -f ~/practice/logrotate_dryrun.txt ]]"
check "logrotate_dryrun.txt has output"         "[[ -s ~/practice/logrotate_dryrun.txt ]]"
check "myapp.logrotate exists"                  "[[ -f ~/practice/myapp.logrotate ]]"
check "myapp.logrotate has daily"               "grep -q 'daily' ~/practice/myapp.logrotate"
check "myapp.logrotate has rotate 30"           "grep -q 'rotate 30' ~/practice/myapp.logrotate"
check "myapp.logrotate has compress"            "grep -q 'compress' ~/practice/myapp.logrotate"
check "myapp.logrotate has delaycompress"       "grep -q 'delaycompress' ~/practice/myapp.logrotate"
check "myapp.logrotate has dateext"             "grep -q 'dateext' ~/practice/myapp.logrotate"
check "myapp.logrotate has postrotate"          "grep -q 'postrotate' ~/practice/myapp.logrotate"
check "logrotate_result.txt exists"             "[[ -f ~/practice/logrotate_result.txt ]]"
check "journal_usage.txt exists"                "[[ -f ~/practice/journal_usage.txt ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
