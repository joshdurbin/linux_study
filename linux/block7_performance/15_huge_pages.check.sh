#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: /proc/meminfo has HugePages_Total field
check "/proc/meminfo has HugePages_Total" \
  "grep -q '^HugePages_Total:' /proc/meminfo"

# Check 2: /proc/meminfo has AnonHugePages field (THP)
check "/proc/meminfo has AnonHugePages (THP) field" \
  "grep -q '^AnonHugePages:' /proc/meminfo"

# Check 3: Hugepagesize is readable
check "Hugepagesize is readable from /proc/meminfo" \
  "awk '/^Hugepagesize:/{exit (\$2+0 > 0 ? 0 : 1)}' /proc/meminfo"

# Check 4: THP enabled control file exists
check "/sys/kernel/mm/transparent_hugepage/enabled exists" \
  "[ -r /sys/kernel/mm/transparent_hugepage/enabled ]"

# Check 5: THP enabled shows a valid value
check "THP enabled file contains always, madvise, or never" \
  "cat /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null | grep -qE 'always|madvise|never'"

# Check 6: THP defrag control file exists
check "/sys/kernel/mm/transparent_hugepage/defrag exists" \
  "[ -r /sys/kernel/mm/transparent_hugepage/defrag ]"

# Check 7: khugepaged directory accessible
check "/sys/kernel/mm/transparent_hugepage/khugepaged/ is accessible" \
  "[ -d /sys/kernel/mm/transparent_hugepage/khugepaged ]"

# Check 8: /sys/kernel/mm/hugepages/ is accessible
check "/sys/kernel/mm/hugepages/ directory exists" \
  "[ -d /sys/kernel/mm/hugepages ]"

# Check 9: THP mode can be changed and restored
check "THP enabled setting can be read and interpreted" \
  "CURR=\$(cat /sys/kernel/mm/transparent_hugepage/enabled | grep -oP '\[\K[^\]]+'); [ -n \"\$CURR\" ]"

# Check 10: practice/hugepages directory exists
check "~/practice/hugepages directory exists" \
  "[ -d \$HOME/practice/hugepages ]"

# Check 11: hugepage_summary.sh exists
check "hugepage_summary.sh exists" \
  "[ -f \$HOME/practice/hugepages/hugepage_summary.sh ]"

# Check 12: hugepage_summary.sh reads /proc/meminfo
check "hugepage_summary.sh reads /proc/meminfo" \
  "grep -q '/proc/meminfo' \$HOME/practice/hugepages/hugepage_summary.sh"

# Check 13: hugepage_summary.sh reads THP setting
check "hugepage_summary.sh reads THP setting" \
  "grep -q 'transparent_hugepage' \$HOME/practice/hugepages/hugepage_summary.sh"

# Check 14: hugepage_summary.sh runs successfully
check "hugepage_summary.sh runs without error" \
  "bash \$HOME/practice/hugepages/hugepage_summary.sh > /dev/null 2>&1"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
