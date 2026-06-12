#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "~/practice/flamegraph_workflow.sh exists" "[[ -f ~/practice/flamegraph_workflow.sh ]]"
check "flamegraph_workflow.sh is executable" "[[ -x ~/practice/flamegraph_workflow.sh ]]"
check "flamegraph_workflow.sh mentions 'perf script'" "grep -q 'perf script' ~/practice/flamegraph_workflow.sh"
check "flamegraph_workflow.sh mentions 'stackcollapse'" "grep -q 'stackcollapse' ~/practice/flamegraph_workflow.sh"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
