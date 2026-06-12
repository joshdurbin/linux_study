#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "practice directory exists" "[[ -d ~/practice ]]"
check "apiserver_notes.txt exists" "[[ -f ~/practice/apiserver_notes.txt ]]"
check "notes file is non-empty" "[[ -s ~/practice/apiserver_notes.txt ]]"
check "notes mention authentication or authn" "grep -qiE 'authn|authenticat' ~/practice/apiserver_notes.txt"
check "notes mention RBAC or authorization" "grep -qiE 'rbac|authori' ~/practice/apiserver_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
