#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "kubelet_notes.txt exists" "[[ -f ~/practice/kubelet_notes.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/kubelet_notes.txt ]]"
check "notes mention pod lifecycle or phase" "grep -qiE 'lifecycle|pending|running|phase' ~/practice/kubelet_notes.txt"
check "notes mention CRI or container runtime" "grep -qiE 'cri|container.?runtime' ~/practice/kubelet_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
