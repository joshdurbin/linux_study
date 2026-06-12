#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: /proc/cpuinfo is readable and has cpu MHz field
check "/proc/cpuinfo has cpu MHz field" \
  "grep -q 'cpu MHz' /proc/cpuinfo"

# Check 2: /sys/devices/system/cpu/ exists
check "/sys/devices/system/cpu/ directory exists" \
  "[ -d /sys/devices/system/cpu ]"

# Check 3: cpufreq directory accessible OR graceful fallback works
check "cpufreq info is accessible (sysfs or /proc/cpuinfo fallback)" \
  "[ -d /sys/devices/system/cpu/cpu0/cpufreq ] || grep -q 'cpu MHz' /proc/cpuinfo"

# Check 4: nproc is available (from block5/15)
check "nproc is available" \
  "command -v nproc > /dev/null 2>&1 && [ \"\$(nproc)\" -ge 1 ]"

# Check 5: scaling_governor is readable (when available)
check "scaling_governor or /proc/cpuinfo provides frequency info" \
  "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor > /dev/null 2>&1 || \
   grep -q 'cpu MHz' /proc/cpuinfo"

# Check 6: cpuidle directory exists or sysfs has power info
check "CPU idle/power info is accessible via /sys" \
  "[ -d /sys/devices/system/cpu/cpu0/cpuidle ] || \
   [ -d /sys/devices/system/cpu/cpufreq ] || \
   [ -d /sys/devices/system/cpu/cpu0/cpufreq ]"

# Check 7: turbo boost status readable (Intel or AMD) or gracefully absent
check "Turbo boost status check does not crash" \
  "cat /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null 2>&1 || \
   cat /sys/devices/system/cpu/cpufreq/boost > /dev/null 2>&1 || \
   echo 'no turbo control' > /dev/null"

# Check 8: practice/cpufreq directory exists
check "~/practice/cpufreq directory exists" \
  "[ -d \$HOME/practice/cpufreq ]"

# Check 9: cpu_power_summary.sh exists
check "cpu_power_summary.sh exists" \
  "[ -f \$HOME/practice/cpufreq/cpu_power_summary.sh ]"

# Check 10: cpu_power_summary.sh references /proc/cpuinfo or sysfs
check "cpu_power_summary.sh reads frequency info" \
  "grep -qE '/proc/cpuinfo|scaling_cur_freq|cpu MHz' \$HOME/practice/cpufreq/cpu_power_summary.sh"

# Check 11: cpu_power_summary.sh checks governor
check "cpu_power_summary.sh references governor" \
  "grep -q 'governor\|GOV' \$HOME/practice/cpufreq/cpu_power_summary.sh"

# Check 12: cpu_power_summary.sh runs without crash
check "cpu_power_summary.sh runs successfully" \
  "bash \$HOME/practice/cpufreq/cpu_power_summary.sh > /dev/null 2>&1"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
