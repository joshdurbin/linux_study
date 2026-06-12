#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: overcommit_memory is readable
check "/proc/sys/vm/overcommit_memory is readable" \
  "[ -r /proc/sys/vm/overcommit_memory ] && grep -qE '^[012]$' /proc/sys/vm/overcommit_memory"

# Check 2: overcommit_ratio is readable
check "/proc/sys/vm/overcommit_ratio is readable" \
  "[ -r /proc/sys/vm/overcommit_ratio ] && [ \"\$(cat /proc/sys/vm/overcommit_ratio)\" -gt 0 ]"

# Check 3: CommitLimit is in /proc/meminfo
check "/proc/meminfo has CommitLimit field" \
  "grep -q '^CommitLimit:' /proc/meminfo"

# Check 4: Committed_AS is in /proc/meminfo
check "/proc/meminfo has Committed_AS field" \
  "grep -q '^Committed_AS:' /proc/meminfo"

# Check 5: oom_score is readable for current process
check "/proc/self/oom_score is readable" \
  "[ -r /proc/self/oom_score ] && grep -qE '^[0-9]+$' /proc/self/oom_score"

# Check 6: oom_score_adj is readable
check "/proc/self/oom_score_adj is readable" \
  "[ -r /proc/self/oom_score_adj ]"

# Check 7: oom_score_adj for own processes can be changed
check "oom_score_adj can be set for own process" \
  "sleep 60 & PID=\$!; sleep 0.1; echo 100 > /proc/\$PID/oom_score_adj && \
   [ \"\$(cat /proc/\$PID/oom_score_adj)\" = '100' ]; kill \$PID 2>/dev/null"

# Check 8: PID 1 has oom_score_adj = -1000
check "PID 1 (systemd/init) has oom_score_adj -1000" \
  "[ \"\$(cat /proc/1/oom_score_adj 2>/dev/null)\" = '-1000' ]"

# Check 9: vm.swappiness is readable
check "vm.swappiness sysctl is readable" \
  "sysctl -n vm.swappiness > /dev/null 2>&1"

# Check 10: practice/oom directory exists
check "~/practice/oom directory exists" \
  "[ -d \$HOME/practice/oom ]"

# Check 11: mem_pressure.sh exists and runs
check "mem_pressure.sh exists and runs successfully" \
  "[ -f \$HOME/practice/oom/mem_pressure.sh ] && \
   bash \$HOME/practice/oom/mem_pressure.sh > /dev/null 2>&1"

# Check 12: mem_pressure.sh reads /proc/meminfo
check "mem_pressure.sh reads /proc/meminfo" \
  "grep -q '/proc/meminfo' \$HOME/practice/oom/mem_pressure.sh"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
