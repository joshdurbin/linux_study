#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: AppArmor module parameter is readable
check "AppArmor enabled parameter is readable" \
  "[ -f /sys/module/apparmor/parameters/enabled ] || [ -d /sys/kernel/security/apparmor ]"

# Check 2: AppArmor profile directory exists
check "/etc/apparmor.d/ exists and contains profiles" \
  "[ -d /etc/apparmor.d ] && ls /etc/apparmor.d/ | grep -q '.'"

# Check 3: apparmor_parser is available
check "apparmor_parser is available" \
  "command -v apparmor_parser > /dev/null 2>&1"

# Check 4: aa-status or apparmor_status is available
check "aa-status or apparmor_status is available" \
  "command -v aa-status > /dev/null 2>&1 || command -v apparmor_status > /dev/null 2>&1"

# Check 5: AppArmor is enabled
check "AppArmor is loaded in kernel" \
  "cat /sys/module/apparmor/parameters/enabled 2>/dev/null | grep -qi 'Y' || \
   sudo aa-status 2>/dev/null | grep -q 'profiles are loaded'"

# Check 6: there are profiles loaded
check "AppArmor has at least one loaded profile" \
  "sudo aa-status 2>/dev/null | grep -qE '[0-9]+ profiles are loaded' || \
   ls /etc/apparmor.d/ | grep -qv '^$'"

# Check 7: mac practice directory exists
check "~/practice/mac directory exists" \
  "[ -d \$HOME/practice/mac ]"

# Check 8: mac_summary.sh exists
check "mac_summary.sh exists" \
  "[ -f \$HOME/practice/mac/mac_summary.sh ]"

# Check 9: mac_summary.sh references AppArmor
check "mac_summary.sh references AppArmor" \
  "grep -qi 'apparmor\|aa-status' \$HOME/practice/mac/mac_summary.sh"

# Check 10: mac_summary.sh runs without crash
check "mac_summary.sh executes successfully" \
  "bash \$HOME/practice/mac/mac_summary.sh > /dev/null 2>&1"

# Check 11: journalctl or dmesg can show kernel security messages
check "kernel security messages accessible via dmesg or journalctl" \
  "dmesg > /dev/null 2>&1 || journalctl -k -n 1 > /dev/null 2>&1"

# Check 12: aa-enforce / aa-complain available
check "aa-enforce is available" \
  "command -v aa-enforce > /dev/null 2>&1"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
