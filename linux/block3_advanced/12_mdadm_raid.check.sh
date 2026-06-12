#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: mdadm is available
check "mdadm is available" \
  "command -v mdadm > /dev/null 2>&1"

# Check 2: /proc/mdstat is readable
check "/proc/mdstat is readable" \
  "[ -r /proc/mdstat ]"

# Check 3: /proc/mdstat has Personalities line
check "/proc/mdstat has Personalities line" \
  "grep -q '^Personalities' /proc/mdstat"

# Check 4: md kernel module support
check "md kernel module is loaded or compiled in" \
  "grep -q 'md' /proc/mdstat || lsmod 2>/dev/null | grep -q '^md' || \
   cat /lib/modules/\$(uname -r)/modules.builtin 2>/dev/null | grep -q 'md/md-mod'"

# Check 5: practice/raid directory exists
check "~/practice/raid directory exists" \
  "[ -d \$HOME/practice/raid ]"

# Check 6: raid_health.sh exists
check "raid_health.sh exists" \
  "[ -f \$HOME/practice/raid/raid_health.sh ]"

# Check 7: raid_health.sh reads /proc/mdstat
check "raid_health.sh reads /proc/mdstat" \
  "grep -q '/proc/mdstat' \$HOME/practice/raid/raid_health.sh"

# Check 8: raid_health.sh runs without crash
check "raid_health.sh runs successfully" \
  "bash \$HOME/practice/raid/raid_health.sh > /dev/null 2>&1"

# Check 9: losetup is available (needed for practice)
check "losetup is available" \
  "command -v losetup > /dev/null 2>&1"

# Check 10: mdadm --detail can be called (even if no arrays)
check "mdadm --detail syntax is accepted" \
  "sudo mdadm --detail /dev/md0 > /dev/null 2>&1 || sudo mdadm --detail --scan > /dev/null 2>&1"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
