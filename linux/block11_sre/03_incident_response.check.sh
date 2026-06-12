#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "incident_runbook.md exists" "[[ -f ~/practice/incident_runbook.md ]]"
check "runbook is non-empty" "[[ -s ~/practice/incident_runbook.md ]]"
check "runbook mentions incident lifecycle or phases" "grep -qiE 'lifecycle|detection|mitigation|triage' ~/practice/incident_runbook.md"
check "runbook mentions roles or IC" "grep -qiE 'incident.?commander|\bic\b|roles' ~/practice/incident_runbook.md"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
