#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "smaps_top.txt exists" "[[ -f ~/practice/smaps_top.txt ]]"
check "smaps_top.txt has memory data" "[[ -s ~/practice/smaps_top.txt ]]"
check "process_memory.txt exists" "[[ -f ~/practice/process_memory.txt ]]"
check "process_memory.txt has VmRSS" "grep -q 'VmRSS' ~/practice/process_memory.txt"
check "gcore_notes.txt exists" "[[ -f ~/practice/gcore_notes.txt ]]"
check "gcore_notes.txt mentions ptrace or core dump" "grep -qiE '(ptrace|core dump|gcore)' ~/practice/gcore_notes.txt"
check "pprof_profiles.txt exists" "[[ -f ~/practice/pprof_profiles.txt ]]"
check "pprof_profiles.txt has 6+ lines" "[[ $(wc -l < ~/practice/pprof_profiles.txt) -ge 6 ]]"
check "pprof_profiles.txt mentions heap" "grep -qi 'heap' ~/practice/pprof_profiles.txt"
check "page_faults.txt exists" "[[ -f ~/practice/page_faults.txt ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
