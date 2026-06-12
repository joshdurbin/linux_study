#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "monitoring_notes.txt exists" "[[ -f ~/practice/monitoring_notes.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/monitoring_notes.txt ]]"
check "notes mention golden signals or latency/traffic/errors/saturation" "grep -qiE 'golden.?signal|latency|saturation' ~/practice/monitoring_notes.txt"
check "notes mention alerting or SLO" "grep -qiE 'alert|slo' ~/practice/monitoring_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
