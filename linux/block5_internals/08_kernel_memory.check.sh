#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: /proc/meminfo is readable
check "/proc/meminfo is readable" \
  "[ -r /proc/meminfo ]"

# Check 2: /proc/meminfo has MemAvailable field
check "/proc/meminfo contains MemAvailable" \
  "grep -q MemAvailable /proc/meminfo"

# Check 3: /proc/self/maps is readable
check "/proc/self/maps is readable" \
  "[ -r /proc/self/maps ]"

# Check 4: stack region exists in maps
check "[stack] region exists in /proc/self/maps" \
  "grep -q '\[stack\]' /proc/self/maps"

# Check 5: getconf PAGE_SIZE works
check "getconf PAGE_SIZE returns 4096" \
  "[ \$(getconf PAGE_SIZE) -eq 4096 ]"

# Check 6: practice directory exists
check "~/practice directory exists" \
  "[ -d \$HOME/practice ]"

# Check 7: memory_notes.txt exists
check "~/practice/memory_notes.txt exists" \
  "[ -f \$HOME/practice/memory_notes.txt ]"

# Check 8: memory_notes.txt contains MemAvailable
check "memory_notes.txt contains MemAvailable" \
  "grep -q 'MemAvailable' \$HOME/practice/memory_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
