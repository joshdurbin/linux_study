#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: & backgrounding works and $! is set
check "\$! is set after backgrounding a job" \
  "sleep 60 & BG_PID=\$!; kill \$BG_PID 2>/dev/null; [ -n \"\$BG_PID\" ]"

# Check 2: jobs reports background jobs
check "jobs lists running background jobs" \
  "sleep 60 & sleep 0.1; jobs | grep -q 'sleep'; kill %1 2>/dev/null"

# Check 3: wait returns exit code of background job
check "wait returns 0 for a successful background job" \
  "true & wait \$!; [ \$? -eq 0 ]"

check "wait returns 1 for a failing background job" \
  "false & wait \$!; [ \$? -eq 1 ]"

# Check 5: kill by job spec works
check "kill %1 terminates job 1" \
  "sleep 100 & JID=\$!; kill %1 2>/dev/null; sleep 0.2; ! ps -p \$JID > /dev/null 2>&1"

# Check 6: disown removes job from job table
check "disown removes job from jobs list" \
  "sleep 200 & DPID=\$!; disown; result=\$(jobs); kill \$DPID 2>/dev/null; [ -z \"\$result\" ]"

# Check 7: practice/jobs directory exists
check "~/practice/jobs directory exists" \
  "[ -d \$HOME/practice/jobs ]"

# Check 8: wait_demo.sh exists and contains wait
check "wait_demo.sh exists" \
  "[ -f \$HOME/practice/jobs/wait_demo.sh ]"

check "wait_demo.sh uses wait" \
  "grep -q 'wait' \$HOME/practice/jobs/wait_demo.sh"

# Check 10: parallel.sh exists and uses wait in a loop or sequence
check "parallel.sh exists" \
  "[ -f \$HOME/practice/jobs/parallel.sh ]"

check "parallel.sh uses wait" \
  "grep -q 'wait' \$HOME/practice/jobs/parallel.sh"

# Check 12: nohup is available
check "nohup is available" \
  "command -v nohup > /dev/null 2>&1"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
