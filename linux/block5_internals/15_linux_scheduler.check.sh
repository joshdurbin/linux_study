#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: CFS parameters are readable
check "/proc/sys/kernel/sched_latency_ns is readable" \
  "[ -r /proc/sys/kernel/sched_latency_ns ] && grep -q '[0-9]' /proc/sys/kernel/sched_latency_ns"

check "/proc/sys/kernel/sched_min_granularity_ns is readable" \
  "[ -r /proc/sys/kernel/sched_min_granularity_ns ]"

# Check 3: nice is available
check "nice is available" \
  "command -v nice > /dev/null 2>&1"

# Check 4: renice is available
check "renice is available" \
  "command -v renice > /dev/null 2>&1"

# Check 5: nice changes the NI value of a process
check "nice -n 15 sets NI=15 on a background process" \
  "nice -n 15 sleep 60 & PID=\$!; sleep 0.2; NI=\$(ps -o ni= -p \$PID | tr -d ' '); kill \$PID 2>/dev/null; [ \"\$NI\" = '15' ]"

# Check 6: renice changes nice value of running process
check "renice changes NI of a running process" \
  "sleep 60 & PID=\$!; sleep 0.1; renice -n 12 -p \$PID > /dev/null; sleep 0.1; NI=\$(ps -o ni= -p \$PID | tr -d ' '); kill \$PID 2>/dev/null; [ \"\$NI\" = '12' ]"

# Check 7: chrt is available
check "chrt is available" \
  "command -v chrt > /dev/null 2>&1"

# Check 8: chrt shows scheduling policy of this shell
check "chrt -p \$\$ reports a scheduling policy" \
  "chrt -p \$\$ 2>/dev/null | grep -q 'scheduling policy'"

# Check 9: normal processes use SCHED_OTHER
check "shell runs under SCHED_OTHER" \
  "chrt -p \$\$ 2>/dev/null | grep -q 'SCHED_OTHER'"

# Check 10: taskset is available
check "taskset is available" \
  "command -v taskset > /dev/null 2>&1"

# Check 11: taskset can pin a process and report affinity
check "taskset -c 0 sets CPU affinity and taskset -cp reports it" \
  "taskset -c 0 sleep 60 & PID=\$!; sleep 0.1; AFF=\$(taskset -cp \$PID 2>/dev/null); kill \$PID 2>/dev/null; echo \"\$AFF\" | grep -q '0'"

# Check 12: nproc is available
check "nproc reports number of CPUs" \
  "nproc > /dev/null 2>&1 && [ \"\$(nproc)\" -ge 1 ]"

# Check 13: scheduler practice dir exists
check "~/practice/scheduler directory exists" \
  "[ -d \$HOME/practice/scheduler ]"

# Check 14: batch_job.sh exists and uses nice
check "batch_job.sh exists" \
  "[ -f \$HOME/practice/scheduler/batch_job.sh ]"

check "batch_job.sh uses nice" \
  "grep -q 'nice' \$HOME/practice/scheduler/batch_job.sh"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
