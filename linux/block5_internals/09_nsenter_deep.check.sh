#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "my_namespaces.txt exists" "[[ -f ~/practice/my_namespaces.txt ]]"
check "my_namespaces.txt has net namespace" "grep -q 'net' ~/practice/my_namespaces.txt"
check "my_namespaces.txt has pid namespace" "grep -q 'pid' ~/practice/my_namespaces.txt"
check "lsns_output.txt exists" "[[ -f ~/practice/lsns_output.txt ]]"
check "ns_diff.txt exists" "[[ -f ~/practice/ns_diff.txt ]]"
check "unshare_net.txt exists" "[[ -f ~/practice/unshare_net.txt ]]"
check "unshare_net.txt mentions lo or loopback" "grep -qiE '(lo|loopback|isolated)' ~/practice/unshare_net.txt"
check "nsenter_hostname.txt exists" "[[ -f ~/practice/nsenter_hostname.txt ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
