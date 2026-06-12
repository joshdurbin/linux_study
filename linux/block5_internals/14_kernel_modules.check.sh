#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "modules_inventory.txt exists"         "[[ -f ~/practice/modules_inventory.txt ]]"
check "modules_inventory.txt has modules"    "grep -qE '^[a-z]' ~/practice/modules_inventory.txt"
check "modinfo_output.txt exists"            "[[ -f ~/practice/modinfo_output.txt ]]"
check "modinfo_output.txt is non-empty"      "[[ -s ~/practice/modinfo_output.txt ]]"
check "module_load.txt exists"               "[[ -f ~/practice/module_load.txt ]]"
check "module_deps.txt exists"               "[[ -f ~/practice/module_deps.txt ]]"
check "module_params.txt exists"             "[[ -f ~/practice/module_params.txt ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
