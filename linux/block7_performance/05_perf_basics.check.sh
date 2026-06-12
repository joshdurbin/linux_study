#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "~/practice/perf_notes.txt exists" "[[ -f ~/practice/perf_notes.txt ]]"
check "perf_notes.txt is non-empty" "[[ -s ~/practice/perf_notes.txt ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
