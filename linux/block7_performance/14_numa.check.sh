#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: /sys/devices/system/node/ exists
check "/sys/devices/system/node/ directory exists" \
  "[ -d /sys/devices/system/node ]"

# Check 2: At least node0 exists
check "node0 exists in /sys/devices/system/node/" \
  "[ -d /sys/devices/system/node/node0 ]"

# Check 3: node0 cpulist is readable
check "node0 cpulist is readable" \
  "[ -r /sys/devices/system/node/node0/cpulist ] && [ -n \"\$(cat /sys/devices/system/node/node0/cpulist)\" ]"

# Check 4: node0 meminfo is readable
check "node0 meminfo is readable" \
  "grep -q 'MemTotal' /sys/devices/system/node/node0/meminfo"

# Check 5: numactl is available
check "numactl is available" \
  "command -v numactl > /dev/null 2>&1"

# Check 6: numastat is available
check "numastat is available" \
  "command -v numastat > /dev/null 2>&1 || [ -f /sys/devices/system/node/node0/numastat ]"

# Check 7: numactl --hardware runs
check "numactl --hardware runs successfully" \
  "numactl --hardware > /dev/null 2>&1"

# Check 8: kernel.numa_balancing is readable
check "kernel.numa_balancing sysctl is readable" \
  "sysctl -n kernel.numa_balancing > /dev/null 2>&1"

# Check 9: /proc/self/numa_maps is readable
check "/proc/self/numa_maps is readable" \
  "[ -r /proc/self/numa_maps ]"

# Check 10: lscpu shows NUMA info
check "lscpu is available" \
  "command -v lscpu > /dev/null 2>&1"

# Check 11: practice/numa directory exists
check "~/practice/numa directory exists" \
  "[ -d \$HOME/practice/numa ]"

# Check 12: numa_summary.sh exists
check "numa_summary.sh exists" \
  "[ -f \$HOME/practice/numa/numa_summary.sh ]"

# Check 13: numa_summary.sh reads from /sys/devices/system/node
check "numa_summary.sh reads NUMA node info" \
  "grep -q 'system/node' \$HOME/practice/numa/numa_summary.sh"

# Check 14: numa_summary.sh runs without crash
check "numa_summary.sh executes successfully" \
  "bash \$HOME/practice/numa/numa_summary.sh > /dev/null 2>&1"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
