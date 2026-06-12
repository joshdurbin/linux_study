#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "sre_readiness.txt exists" "[[ -f ~/practice/sre_readiness.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/sre_readiness.txt ]]"
check "notes mention SLO or SLI or monitoring" "grep -qiE 'slo|sli|monitoring' ~/practice/sre_readiness.txt"
check "notes mention readiness or maturity or checklist" "grep -qiE 'readiness|maturity|checklist|prr' ~/practice/sre_readiness.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
