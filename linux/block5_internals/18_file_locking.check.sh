#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: flock is available
check "flock is available" \
  "command -v flock > /dev/null 2>&1"

# Check 2: /proc/locks is readable
check "/proc/locks is readable" \
  "[ -r /proc/locks ]"

# Check 3: flock -n returns 0 when lock is free
check "flock -n returns 0 when lock is free" \
  "LFILE=\$(mktemp) && flock -n \"\$LFILE\" true; RC=\$?; rm -f \"\$LFILE\"; [ \$RC -eq 0 ]"

# Check 4: flock -n returns non-zero when lock is held
check "flock -n returns non-zero when lock is already held" \
  "LFILE=\$(mktemp) && \
   exec 9>\"\$LFILE\" && flock 9 && \
   flock -n \"\$LFILE\" true; RC=\$?; \
   flock -u 9; exec 9>&-; rm -f \"\$LFILE\"; \
   [ \$RC -ne 0 ]"

# Check 5: shared locks are compatible with each other
check "two shared locks can be held simultaneously" \
  "LFILE=\$(mktemp) && \
   exec 8>\"\$LFILE\"; flock -s 8 && \
   flock -sn \"\$LFILE\" true; RC=\$?; \
   flock -u 8; exec 8>&-; rm -f \"\$LFILE\"; \
   [ \$RC -eq 0 ]"

# Check 6: exclusive lock blocks exclusive lock
check "exclusive lock blocks another exclusive lock (non-blocking)" \
  "LFILE=\$(mktemp) && \
   exec 8>\"\$LFILE\"; flock 8 && \
   flock -n \"\$LFILE\" true; RC=\$?; \
   flock -u 8; exec 8>&-; rm -f \"\$LFILE\"; \
   [ \$RC -ne 0 ]"

# Check 7: practice directory exists
check "~/practice/file_locking directory exists" \
  "[ -d \$HOME/practice/file_locking ]"

# Check 8: safe_runner.sh exists
check "safe_runner.sh exists" \
  "[ -f \$HOME/practice/file_locking/safe_runner.sh ]"

# Check 9: safe_runner.sh uses flock
check "safe_runner.sh uses flock" \
  "grep -q 'flock' \$HOME/practice/file_locking/safe_runner.sh"

# Check 10: safe_runner.sh runs successfully
check "safe_runner.sh runs without error" \
  "bash \$HOME/practice/file_locking/safe_runner.sh > /dev/null 2>&1"

# Check 11: flock -w with timeout works
check "flock -w timeout parameter is accepted" \
  "LFILE=\$(mktemp) && flock -w 1 \"\$LFILE\" true > /dev/null 2>&1; RC=\$?; rm -f \"\$LFILE\"; [ \$RC -eq 0 ]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
