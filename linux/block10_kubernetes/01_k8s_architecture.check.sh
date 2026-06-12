#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "k8s_arch.txt exists" "[[ -f ~/practice/k8s_arch.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/k8s_arch.txt ]]"
check "notes contain etcd" "grep -q 'etcd' ~/practice/k8s_arch.txt"
check "notes contain kubelet" "grep -q 'kubelet' ~/practice/k8s_arch.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
