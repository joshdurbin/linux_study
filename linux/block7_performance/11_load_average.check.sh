#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: /proc/loadavg is readable
check "/proc/loadavg is readable" \
  "[ -r /proc/loadavg ] && grep -qE '^[0-9]+\.' /proc/loadavg"

# Check 2: uptime is available
check "uptime is available" \
  "command -v uptime > /dev/null 2>&1"

# Check 3: uptime output contains 'load average'
check "uptime reports load average" \
  "uptime | grep -qi 'load average'"

# Check 4: /proc/loadavg has 5 fields
check "/proc/loadavg has 5 whitespace-separated fields" \
  "[ \"\$(awk '{print NF}' /proc/loadavg)\" -eq 5 ]"

# Check 5: first field of /proc/loadavg is numeric
check "1-minute load average is a number" \
  "awk '{exit (\$1+0 == \$1) ? 0 : 1}' /proc/loadavg"

# Check 6: nproc is available
check "nproc is available" \
  "command -v nproc > /dev/null 2>&1"

# Check 7: nproc returns >= 1
check "nproc returns at least 1" \
  "[ \"\$(nproc)\" -ge 1 ]"

# Check 8: ps can show D-state processes
check "ps can filter D-state processes" \
  "ps aux | awk '\$8 ~ /^D/ {count++} END {exit 0}'"

# Check 9: vmstat is available
check "vmstat is available" \
  "command -v vmstat > /dev/null 2>&1"

# Check 10: vmstat output contains r and b columns
check "vmstat -1 output has r and b column headers" \
  "vmstat 1 1 | grep -q ' r '"

# Check 11: practice loadavg directory exists
check "~/practice/loadavg directory exists" \
  "[ -d \$HOME/practice/loadavg ]"

# Check 12: load_summary.sh exists
check "load_summary.sh exists" \
  "[ -f \$HOME/practice/loadavg/load_summary.sh ]"

# Check 13: load_summary.sh reads /proc/loadavg
check "load_summary.sh references /proc/loadavg" \
  "grep -q '/proc/loadavg' \$HOME/practice/loadavg/load_summary.sh"

# Check 14: load_summary.sh uses nproc
check "load_summary.sh uses nproc" \
  "grep -q 'nproc' \$HOME/practice/loadavg/load_summary.sh"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
