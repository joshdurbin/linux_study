#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: /sys/fs/cgroup exists
check "/sys/fs/cgroup exists" \
  "[ -d /sys/fs/cgroup ]"

# Check 2: cgroup.controllers file exists (v2 indicator)
check "cgroup.controllers exists (cgroups v2)" \
  "[ -f /sys/fs/cgroup/cgroup.controllers ]"

# Check 3: /proc/self/cgroup is readable
check "/proc/self/cgroup is readable" \
  "[ -r /proc/self/cgroup ]"

# Check 4: /proc/self/cgroup has content
check "/proc/self/cgroup has content" \
  "[ -s /proc/self/cgroup ]"

# Check 5: practice directory exists
check "~/practice directory exists" \
  "[ -d \$HOME/practice ]"

# Check 6: my_cgroup.txt exists
check "~/practice/my_cgroup.txt exists" \
  "[ -f \$HOME/practice/my_cgroup.txt ]"

# Check 7: my_cgroup.txt contains a cgroup path (starts with 0:: or similar)
check "my_cgroup.txt contains a cgroup path" \
  "grep -qE '(0::|/user\.slice|/system\.slice|/init\.scope|cgroup)' \$HOME/practice/my_cgroup.txt"

# Check 8: systemd-cgls or systemctl is available
check "systemctl is available" \
  "command -v systemctl > /dev/null 2>&1"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
