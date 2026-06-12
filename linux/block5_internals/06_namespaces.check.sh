#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: lsns is available
check "lsns command is available" \
  "command -v lsns > /dev/null 2>&1"

# Check 2: unshare is available
check "unshare command is available" \
  "command -v unshare > /dev/null 2>&1"

# Check 3: /proc/self/ns directory exists
check "/proc/self/ns directory exists" \
  "[ -d /proc/self/ns ]"

# Check 4: UTS namespace symlink exists
check "/proc/self/ns/uts exists" \
  "[ -L /proc/self/ns/uts ]"

# Check 5: PID namespace symlink exists
check "/proc/self/ns/pid exists" \
  "[ -L /proc/self/ns/pid ]"

# Check 6: practice directory exists
check "~/practice directory exists" \
  "[ -d \$HOME/practice ]"

# Check 7: namespace_notes.txt exists
check "~/practice/namespace_notes.txt exists" \
  "[ -f \$HOME/practice/namespace_notes.txt ]"

# Check 8: namespace_notes.txt mentions at least 3 namespace types
check "namespace_notes.txt contains at least 3 namespace types" \
  "[[ \$(grep -ciE '(PID|NET|MNT|UTS|IPC|USER|TIME|CGROUP)' \$HOME/practice/namespace_notes.txt) -ge 3 ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
