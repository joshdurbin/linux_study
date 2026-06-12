#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: uname is available and shows kernel version
check "uname -r shows kernel version" \
  "uname -r | grep -qE '^[0-9]+\.[0-9]+'"

# Check 2: Kernel is 5.1+ (io_uring requires 5.1)
check "kernel version is 5.1 or newer" \
  "MAJOR=\$(uname -r | cut -d. -f1); MINOR=\$(uname -r | cut -d. -f2 | cut -d- -f1); \
   [ \"\$MAJOR\" -gt 5 ] || ([ \"\$MAJOR\" -eq 5 ] && [ \"\$MINOR\" -ge 1 ])"

# Check 3: io_uring_disabled sysctl exists or kernel predates it
check "io_uring_disabled sysctl is readable or absent gracefully" \
  "cat /proc/sys/kernel/io_uring_disabled > /dev/null 2>&1 || true"

# Check 4: strace is available (from block5/03)
check "strace is available" \
  "command -v strace > /dev/null 2>&1"

# Check 5: strace can trace io_uring syscalls (flag accepted even if not triggered)
check "strace accepts io_uring trace filter" \
  "strace -e trace=io_uring_setup,io_uring_enter ls /tmp > /dev/null 2>&1; [ \$? -ne 1 ]"

# Check 6: io_uring symbols exist in kernel
check "io_uring symbols present in /proc/kallsyms" \
  "grep -q 'io_uring' /proc/kallsyms 2>/dev/null"

# Check 7: /proc/[pid]/fd can be inspected for io_uring FDs
check "/proc/self/fd is readable" \
  "ls /proc/self/fd > /dev/null 2>&1"

# Check 8: practice/io_uring directory exists
check "~/practice/io_uring directory exists" \
  "[ -d \$HOME/practice/io_uring ]"

# Check 9: check_io_uring.sh exists
check "check_io_uring.sh exists" \
  "[ -f \$HOME/practice/io_uring/check_io_uring.sh ]"

# Check 10: check_io_uring.sh references uname and io_uring
check "check_io_uring.sh checks kernel version and io_uring" \
  "grep -q 'uname' \$HOME/practice/io_uring/check_io_uring.sh && \
   grep -q 'io_uring' \$HOME/practice/io_uring/check_io_uring.sh"

# Check 11: check_io_uring.sh runs without crash
check "check_io_uring.sh runs successfully" \
  "bash \$HOME/practice/io_uring/check_io_uring.sh > /dev/null 2>&1"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
