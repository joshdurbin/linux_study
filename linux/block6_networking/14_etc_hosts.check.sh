#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "hosts_inventory.txt exists"              "[[ -f ~/practice/hosts_inventory.txt ]]"
check "hosts_inventory.txt has /etc/hosts data" "grep -q '127.0.0.1' ~/practice/hosts_inventory.txt"
check "hosts_inventory.txt has nsswitch"        "grep -qi 'files\|dns\|hosts' ~/practice/hosts_inventory.txt"
check "hosts_inventory.txt has resolv.conf"     "grep -qi 'nameserver\|resolv' ~/practice/hosts_inventory.txt"

check "hosts_getent.txt exists"                 "[[ -f ~/practice/hosts_getent.txt ]]"
check "hosts_getent.txt resolved the test host" "grep -q '127.0.0.1' ~/practice/hosts_getent.txt"
check "test entry cleaned up from /etc/hosts"   "! grep -q 'linux-study-test' /etc/hosts"

check "hosts_comparison.txt exists"             "[[ -f ~/practice/hosts_comparison.txt ]]"
check "hosts_comparison.txt is non-empty"       "[[ -s ~/practice/hosts_comparison.txt ]]"

check "hosts_examples.txt exists"               "[[ -f ~/practice/hosts_examples.txt ]]"
check "hosts_examples.txt has 0.0.0.0 block"    "grep -q '0.0.0.0' ~/practice/hosts_examples.txt"
check "hosts_examples.txt has 127.0.0.1 entry"  "grep -q '127.0.0.1' ~/practice/hosts_examples.txt"
check "hosts_examples.txt has alias entry"      "grep -qE '^10\.' ~/practice/hosts_examples.txt"

check "resolv_explained.txt exists"             "[[ -f ~/practice/resolv_explained.txt ]]"
check "resolv_explained.txt mentions nameserver" "grep -qi 'nameserver' ~/practice/resolv_explained.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
