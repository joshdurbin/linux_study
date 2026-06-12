#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: /proc/meminfo is readable and contains expected fields
check "/proc/meminfo is readable and has MemTotal" \
  "grep -q MemTotal /proc/meminfo"

# Check 2: /proc/self/cmdline is readable
check "/proc/self/cmdline is readable" \
  "[ -r /proc/self/cmdline ]"

# Check 3: /proc/uptime exists and has numeric content
check "/proc/uptime contains a number" \
  "cat /proc/uptime | grep -qE '^[0-9]+\.[0-9]+'"

# Check 4: practice directory exists
check "~/practice directory exists" \
  "[ -d \$HOME/practice ]"

# Check 5: proc_notes.txt was created
check "~/practice/proc_notes.txt exists" \
  "[ -f \$HOME/practice/proc_notes.txt ]"

# Check 6: proc_notes.txt contains memory information
check "proc_notes.txt contains MemAvailable or MemTotal" \
  "grep -qE 'Mem(Available|Total|Free)' \$HOME/practice/proc_notes.txt"

# Check 7: /proc/1/cmdline is readable (PID 1 exists)
check "/proc/1/cmdline is readable" \
  "[ -r /proc/1/cmdline ]"

# Check 8: /proc/self/fd directory exists
check "/proc/self/fd directory is accessible" \
  "[ -d /proc/self/fd ]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
