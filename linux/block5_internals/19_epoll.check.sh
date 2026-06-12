#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: strace is available (from block5/03)
check "strace is available" \
  "command -v strace > /dev/null 2>&1"

# Check 2: epoll syscalls exist in the kernel (strace accepts the trace filter)
check "strace accepts epoll trace filter" \
  "strace -e trace=epoll_create1,epoll_wait true > /dev/null 2>&1"

# Check 3: /proc/self/fd directory is accessible
check "/proc/self/fd is accessible" \
  "ls /proc/self/fd > /dev/null 2>&1"

# Check 4: /proc/self/fdinfo is accessible
check "/proc/self/fdinfo is accessible" \
  "ls /proc/self/fdinfo > /dev/null 2>&1"

# Check 5: epoll kernel support (anon_inode:eventpoll can exist)
check "kernel supports eventpoll (epoll)" \
  "python3 -c 'import select; ep = select.epoll(); ep.close()' > /dev/null 2>&1 || \
   strace -e epoll_create1 true 2>&1 | grep -qv 'Unknown syscall'"

# Check 6: O_NONBLOCK flag value is correct (2048 decimal)
check "O_NONBLOCK constant is 2048 (0o4000 octal)" \
  "python3 -c 'import os; assert os.O_NONBLOCK == 2048' > /dev/null 2>&1 || \
   grep -r 'O_NONBLOCK' /usr/include/asm-generic/fcntl.h 2>/dev/null | grep -q '04000'"

# Check 7: practice/epoll directory exists
check "~/practice/epoll directory exists" \
  "[ -d \$HOME/practice/epoll ]"

# Check 8: epoll_observer.sh exists
check "epoll_observer.sh exists" \
  "[ -f \$HOME/practice/epoll/epoll_observer.sh ]"

# Check 9: epoll_observer.sh scans /proc for eventpoll FDs
check "epoll_observer.sh looks for eventpoll in /proc" \
  "grep -q 'eventpoll' \$HOME/practice/epoll/epoll_observer.sh"

# Check 10: epoll_observer.sh runs without crash
check "epoll_observer.sh runs successfully" \
  "bash \$HOME/practice/epoll/epoll_observer.sh > /dev/null 2>&1"

# Check 11: scaling_demo.sh exists
check "scaling_demo.sh exists" \
  "[ -f \$HOME/practice/epoll/scaling_demo.sh ]"

# Check 12: scaling_demo.sh mentions O(n) and O(1) concepts
check "scaling_demo.sh discusses scaling characteristics" \
  "grep -qE 'O\(n\)|O\(1\)|epoll|select' \$HOME/practice/epoll/scaling_demo.sh"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
