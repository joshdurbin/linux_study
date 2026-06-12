#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: flock is available
check "flock is available" \
  "command -v flock > /dev/null 2>&1"

# Check 2: practice directory exists
check "~/practice/script_patterns directory exists" \
  "[ -d \$HOME/practice/script_patterns ]"

# Check 3: locked_job.sh exists and uses flock
check "locked_job.sh exists and uses flock" \
  "[ -f \$HOME/practice/script_patterns/locked_job.sh ] && \
   grep -q 'flock' \$HOME/practice/script_patterns/locked_job.sh"

# Check 4: flock actually prevents concurrent runs
check "flock prevents second instance from running" \
  "LOCK=\$(mktemp) && \
   (flock -n 9 && sleep 5) 9>\"\$LOCK\" & \
   sleep 0.3 && \
   flock -n \"\$LOCK\" echo 'got lock' 2>/dev/null; EC=\$?; \
   kill \$(jobs -p) 2>/dev/null; wait 2>/dev/null; rm -f \"\$LOCK\"; \
   [ \$EC -ne 0 ]"

# Check 5: daemon_sim.sh exists and uses PID file pattern
check "daemon_sim.sh exists" \
  "[ -f \$HOME/practice/script_patterns/daemon_sim.sh ]"

check "daemon_sim.sh writes to a PID file" \
  "grep -q 'PIDFILE\|pidfile\|\.pid' \$HOME/practice/script_patterns/daemon_sim.sh"

check "daemon_sim.sh uses kill -0 to check if process exists" \
  "grep -q 'kill -0' \$HOME/practice/script_patterns/daemon_sim.sh"

# Check 8: atomic write pattern (temp file + mv)
check "setup_idempotent.sh exists" \
  "[ -f \$HOME/practice/script_patterns/setup_idempotent.sh ]"

check "setup_idempotent.sh uses mkdir -p (idempotent mkdir)" \
  "grep -q 'mkdir -p' \$HOME/practice/script_patterns/setup_idempotent.sh"

# Check 10: retry.sh exists and uses a retry loop
check "retry.sh exists" \
  "[ -f \$HOME/practice/script_patterns/retry.sh ]"

check "retry.sh uses a loop with sleep/backoff" \
  "grep -q 'sleep' \$HOME/practice/script_patterns/retry.sh && \
   grep -q 'while\|until' \$HOME/practice/script_patterns/retry.sh"

# Check 12: cleanup_demo.sh uses trap EXIT
check "cleanup_demo.sh exists and uses trap EXIT" \
  "[ -f \$HOME/practice/script_patterns/cleanup_demo.sh ] && \
   grep -q 'trap.*EXIT' \$HOME/practice/script_patterns/cleanup_demo.sh"

# Check 13: mktemp is available
check "mktemp is available" \
  "command -v mktemp > /dev/null 2>&1"

# Check 14: atomic write via mktemp + mv works correctly
check "mktemp + mv provides atomic write" \
  "DEST=\$(mktemp) && \
   TMPF=\$(mktemp \"\${DEST}.XXXXXX\") && \
   echo 'atomic' > \"\$TMPF\" && mv \"\$TMPF\" \"\$DEST\" && \
   [ \"\$(cat \$DEST)\" = 'atomic' ] && rm -f \"\$DEST\""

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
