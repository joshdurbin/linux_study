#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: /proc/self/status Seccomp field is readable
check "/proc/self/status has Seccomp field" \
  "grep -q '^Seccomp:' /proc/self/status"

# Check 2: Seccomp value is 0, 1, or 2
check "Seccomp field value is valid (0, 1, or 2)" \
  "val=\$(awk '/^Seccomp:/{print \$2}' /proc/self/status); [[ \$val =~ ^[012]\$ ]]"

# Check 3: strace is available (introduced in block5/03)
check "strace is available" \
  "command -v strace > /dev/null 2>&1"

# Check 4: strace can show syscall summary for ls
check "strace -c ls produces syscall summary" \
  "strace -c ls /tmp > /dev/null 2>&1"

# Check 5: practice/seccomp directory exists
check "~/practice/seccomp directory exists" \
  "[ -d \$HOME/practice/seccomp ]"

# Check 6: ls_profile.json exists
check "ls_profile.json exists" \
  "[ -f \$HOME/practice/seccomp/ls_profile.json ]"

# Check 7: ls_profile.json is valid JSON with a defaultAction
check "ls_profile.json has defaultAction field" \
  "grep -q 'defaultAction' \$HOME/practice/seccomp/ls_profile.json"

# Check 8: ls_profile.json has syscalls array
check "ls_profile.json has syscalls array" \
  "grep -q 'syscalls' \$HOME/practice/seccomp/ls_profile.json"

# Check 9: deny_mkdir.json exists
check "deny_mkdir.json exists" \
  "[ -f \$HOME/practice/seccomp/deny_mkdir.json ]"

# Check 10: deny_mkdir.json blocks mkdir
check "deny_mkdir.json references mkdir syscall" \
  "grep -q 'mkdir' \$HOME/practice/seccomp/deny_mkdir.json"

# Check 11: deny_mkdir.json uses SCMP_ACT_ERRNO or SCMP_ACT_KILL for mkdir
check "deny_mkdir.json uses a blocking action on mkdir" \
  "grep -q 'SCMP_ACT_ERRNO\|SCMP_ACT_KILL' \$HOME/practice/seccomp/deny_mkdir.json"

# Check 12: check_seccomp.sh exists
check "check_seccomp.sh exists" \
  "[ -f \$HOME/practice/seccomp/check_seccomp.sh ]"

# Check 13: check_seccomp.sh references /proc
check "check_seccomp.sh reads from /proc" \
  "grep -q '/proc' \$HOME/practice/seccomp/check_seccomp.sh"

# Check 14: check_seccomp.sh runs without error
check "check_seccomp.sh runs successfully" \
  "bash \$HOME/practice/seccomp/check_seccomp.sh > /dev/null 2>&1"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
