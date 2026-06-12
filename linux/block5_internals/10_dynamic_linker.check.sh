#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "ldd_output.txt exists" "[[ -f ~/practice/ldd_output.txt ]]"
check "ldd_output.txt mentions libc" "grep -q 'libc' ~/practice/ldd_output.txt"
check "ldconfig_output.txt exists" "[[ -f ~/practice/ldconfig_output.txt ]]"
check "ldconfig_output.txt has library count" "[[ -s ~/practice/ldconfig_output.txt ]]"
check "readelf_bash.txt exists" "[[ -f ~/practice/readelf_bash.txt ]]"
check "readelf_bash.txt has interpreter or NEEDED" "grep -qiE '(interpreter|NEEDED|ld-linux)' ~/practice/readelf_bash.txt"
check "ld_preload_demo.txt exists" "[[ -f ~/practice/ld_preload_demo.txt ]]"
check "ltrace_output.txt exists" "[[ -f ~/practice/ltrace_output.txt ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
