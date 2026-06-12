#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "~/practice/bcc_survey.txt exists" "[[ -f ~/practice/bcc_survey.txt ]]"
check "bcc_survey.txt is non-empty" "[[ -s ~/practice/bcc_survey.txt ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
