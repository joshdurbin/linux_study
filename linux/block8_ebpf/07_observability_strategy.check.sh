#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "~/practice/observability_strategy.txt exists" "[[ -f ~/practice/observability_strategy.txt ]]"
check "observability_strategy.txt is non-empty" "[[ -s ~/practice/observability_strategy.txt ]]"
check "mentions at least two of: strace, perf, bpftrace, eBPF" \
    "[[ \$(grep -oiE 'strace|bpftrace|eBPF|perf' ~/practice/observability_strategy.txt | sort -u | wc -l) -ge 2 ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
