#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: strace is installed
check "strace is installed" \
  "command -v strace > /dev/null 2>&1"

# Check 2: strace can run successfully
check "strace can trace a simple command" \
  "strace -c echo hello > /dev/null 2>&1"

# Check 3: practice directory exists
check "~/practice directory exists" \
  "[ -d \$HOME/practice ]"

# Check 4: strace_output.txt exists
check "~/practice/strace_output.txt exists" \
  "[ -f \$HOME/practice/strace_output.txt ]"

# Check 5: strace_output.txt is not empty
check "strace_output.txt is not empty" \
  "[ -s \$HOME/practice/strace_output.txt ]"

# Check 6: strace_output.txt contains syscall data (look for 'calls' header or a syscall name)
check "strace_output.txt contains syscall data" \
  "grep -qiE '(syscall|calls|mmap|read|write|openat)' \$HOME/practice/strace_output.txt"

# Check 7: /proc/self/syscall is readable
check "/proc/self/syscall is readable" \
  "[ -r /proc/self/syscall ]"

# Check 8: vDSO is visible in process memory maps
check "vdso appears in /proc/self/maps" \
  "grep -q vdso /proc/self/maps"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
