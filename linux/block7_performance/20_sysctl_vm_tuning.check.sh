#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: practice directory exists
check "~/practice/sysctl_vm directory exists" \
  "[ -d \$HOME/practice/sysctl_vm ]"

# Check 2: key vm.* sysctl params are readable
check "vm.swappiness is readable" \
  "sysctl vm.swappiness > /dev/null 2>&1"

check "vm.dirty_ratio is readable" \
  "sysctl vm.dirty_ratio > /dev/null 2>&1"

check "vm.dirty_background_ratio is readable" \
  "sysctl vm.dirty_background_ratio > /dev/null 2>&1"

check "vm.dirty_expire_centisecs is readable" \
  "sysctl vm.dirty_expire_centisecs > /dev/null 2>&1"

check "vm.dirty_writeback_centisecs is readable" \
  "sysctl vm.dirty_writeback_centisecs > /dev/null 2>&1"

check "vm.vfs_cache_pressure is readable" \
  "sysctl vm.vfs_cache_pressure > /dev/null 2>&1"

check "vm.min_free_kbytes is readable" \
  "sysctl vm.min_free_kbytes > /dev/null 2>&1"

# Check 3: /proc/vmstat is readable
check "/proc/vmstat is readable" \
  "[ -r /proc/vmstat ] && wc -l < /proc/vmstat > /dev/null"

# Check 4: /proc/vmstat contains swap and fault fields
check "/proc/vmstat contains pswpin field" \
  "grep -q '^pswpin' /proc/vmstat"

check "/proc/vmstat contains pgmajfault field" \
  "grep -q '^pgmajfault' /proc/vmstat"

check "/proc/vmstat contains nr_dirty field" \
  "grep -q '^nr_dirty' /proc/vmstat"

# Check 5: current_defaults.txt was captured
check "current_defaults.txt exists" \
  "[ -f \$HOME/practice/sysctl_vm/current_defaults.txt ]"

check "current_defaults.txt contains vm.swappiness" \
  "grep -q 'swappiness' \$HOME/practice/sysctl_vm/current_defaults.txt"

# Check 6: database tuning profile exists
check "db_tuning.conf exists" \
  "[ -f \$HOME/practice/sysctl_vm/db_tuning.conf ]"

check "db_tuning.conf contains vm.swappiness" \
  "grep -q 'vm.swappiness' \$HOME/practice/sysctl_vm/db_tuning.conf"

check "db_tuning.conf contains vm.dirty_ratio" \
  "grep -q 'vm.dirty_ratio' \$HOME/practice/sysctl_vm/db_tuning.conf"

check "db_tuning.conf contains fs.file-max" \
  "grep -q 'fs.file-max' \$HOME/practice/sysctl_vm/db_tuning.conf"

# Check 7: vmstat_watch.sh exists
check "vmstat_watch.sh exists" \
  "[ -f \$HOME/practice/sysctl_vm/vmstat_watch.sh ]"

check "vmstat_watch.sh is executable" \
  "[ -x \$HOME/practice/sysctl_vm/vmstat_watch.sh ]"

# Check 8: vmstat_watch.sh references /proc/vmstat
check "vmstat_watch.sh reads /proc/vmstat" \
  "grep -q '/proc/vmstat' \$HOME/practice/sysctl_vm/vmstat_watch.sh"

# Check 9: vmstat_watch.sh references swap fields
check "vmstat_watch.sh references pswpin or pswpout" \
  "grep -qE 'pswpin|pswpout' \$HOME/practice/sysctl_vm/vmstat_watch.sh"

# Check 10: vmstat_watch.sh references page fault fields
check "vmstat_watch.sh references pgfault or pgmajfault" \
  "grep -qE 'pgfault|pgmajfault' \$HOME/practice/sysctl_vm/vmstat_watch.sh"

# Check 11: vmstat_watch.sh runs and produces output (short run)
check "vmstat_watch.sh produces output when run for 3 seconds" \
  "timeout 3 \$HOME/practice/sysctl_vm/vmstat_watch.sh 1 2>&1 | grep -qE '[0-9]'"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
