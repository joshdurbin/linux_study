#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: ulimit is a shell builtin
check "ulimit is available" \
  "type ulimit > /dev/null 2>&1"

# Check 2: ulimit -a produces output
check "ulimit -a lists resource limits" \
  "ulimit -a | grep -q 'open files'"

# Check 3: soft and hard limits are readable
check "ulimit -Sn returns soft open-files limit" \
  "[ \"\$(ulimit -Sn)\" -gt 0 ]"

check "ulimit -Hn returns hard open-files limit" \
  "[ \"\$(ulimit -Hn)\" -gt 0 ]"

# Check 5: /proc/self/limits is readable
check "/proc/self/limits is readable" \
  "[ -r /proc/self/limits ] && grep -q 'open files' /proc/self/limits"

# Check 6: /proc/sys/fs/file-nr is readable
check "/proc/sys/fs/file-nr shows system FD usage" \
  "[ -r /proc/sys/fs/file-nr ] && [ \"\$(awk '{print \$1}' /proc/sys/fs/file-nr)\" -ge 0 ]"

# Check 7: fs.file-max sysctl readable
check "fs.file-max sysctl is readable" \
  "sysctl -n fs.file-max > /dev/null 2>&1"

# Check 8: prlimit is available
check "prlimit is available" \
  "command -v prlimit > /dev/null 2>&1"

# Check 9: prlimit --pid shows current process limits
check "prlimit --pid \$\$ shows limits" \
  "prlimit --pid \$\$ > /dev/null 2>&1"

# Check 10: soft limit can be raised to hard limit
check "ulimit -n can be set to hard limit value" \
  "HARD=\$(ulimit -Hn); ulimit -n \$HARD && [ \"\$(ulimit -Sn)\" -eq \"\$HARD\" ]"

# Check 11: practice/ulimits directory exists
check "~/practice/ulimits directory exists" \
  "[ -d \$HOME/practice/ulimits ]"

# Check 12: myapp.conf exists with correct format
check "myapp.conf exists" \
  "[ -f \$HOME/practice/ulimits/myapp.conf ]"

check "myapp.conf has nofile limits" \
  "grep -q 'nofile' \$HOME/practice/ulimits/myapp.conf"

# Check 14: check_fd_limits.sh exists and runs
check "check_fd_limits.sh exists and runs" \
  "[ -f \$HOME/practice/ulimits/check_fd_limits.sh ] && \
   bash \$HOME/practice/ulimits/check_fd_limits.sh > /dev/null 2>&1"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
