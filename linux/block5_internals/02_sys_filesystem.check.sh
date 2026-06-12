#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: /sys/class/net exists
check "/sys/class/net exists" \
  "[ -d /sys/class/net ]"

# Check 2: sysctl command is available
check "sysctl command is available" \
  "command -v sysctl > /dev/null 2>&1"

# Check 3: vm.swappiness is readable
check "vm.swappiness is readable via sysctl" \
  "sysctl vm.swappiness > /dev/null 2>&1"

# Check 4: /proc/sys/vm/swappiness is a readable file
check "/proc/sys/vm/swappiness is readable" \
  "[ -r /proc/sys/vm/swappiness ]"

# Check 5: net.ipv4.ip_forward is readable
check "net.ipv4.ip_forward is readable" \
  "sysctl net.ipv4.ip_forward > /dev/null 2>&1"

# Check 6: practice directory exists
check "~/practice directory exists" \
  "[ -d \$HOME/practice ]"

# Check 7: sysctl_notes.txt was created
check "~/practice/sysctl_notes.txt exists" \
  "[ -f \$HOME/practice/sysctl_notes.txt ]"

# Check 8: sysctl_notes.txt contains vm.swappiness
check "sysctl_notes.txt contains vm.swappiness" \
  "grep -q 'swappiness' \$HOME/practice/sysctl_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
