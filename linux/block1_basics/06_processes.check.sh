#!/bin/bash
PASS=0
FAIL=0

check() {
  local desc="$1"
  local result="$2"
  if [[ "$result" == "ok" ]]; then
    echo "PASS: $desc"
    ((PASS++))
  else
    echo "FAIL: $desc — $result"
    ((FAIL++))
  fi
}

# Task 1: sleep_ps.txt exists and references sleep
[[ -d ~/proclab ]] && r="ok" || r="~/proclab directory not found"
check "~/proclab exists" "$r"

[[ -f ~/proclab/sleep_ps.txt ]] && r="ok" || r="sleep_ps.txt not found"
check "sleep_ps.txt exists" "$r"

if [[ -f ~/proclab/sleep_ps.txt ]]; then
  grep -q "sleep" ~/proclab/sleep_ps.txt && r="ok" || r="sleep_ps.txt doesn't mention 'sleep'"
  check "sleep_ps.txt references sleep process" "$r"
fi

# Task 2: all_processes.txt and process_count.txt
[[ -f ~/proclab/all_processes.txt ]] && r="ok" || r="all_processes.txt not found"
check "all_processes.txt exists" "$r"

if [[ -f ~/proclab/all_processes.txt ]]; then
  lines=$(wc -l < ~/proclab/all_processes.txt)
  [[ $lines -gt 5 ]] && r="ok" || r="all_processes.txt has only $lines lines — expected many processes"
  check "all_processes.txt has many lines" "$r"
fi

[[ -f ~/proclab/process_count.txt ]] && r="ok" || r="process_count.txt not found"
check "process_count.txt exists" "$r"

if [[ -f ~/proclab/process_count.txt ]]; then
  val=$(tr -d '[:space:]' < ~/proclab/process_count.txt)
  [[ "$val" =~ ^[0-9]+$ ]] && r="ok" || r="process_count.txt contains '$val' (expected a number)"
  check "process_count.txt contains a number" "$r"
fi

# Task 3: after_kill.txt exists and indicates completion
[[ -f ~/proclab/after_kill.txt ]] && r="ok" || r="after_kill.txt not found"
check "after_kill.txt exists" "$r"

# Task 4: jobs_output.txt and jobs_after.txt
[[ -f ~/proclab/jobs_output.txt ]] && r="ok" || r="jobs_output.txt not found"
check "jobs_output.txt exists" "$r"

[[ -f ~/proclab/jobs_after.txt ]] && r="ok" || r="jobs_after.txt not found"
check "jobs_after.txt exists" "$r"

# Verify kill/pgrep tools are available
command -v kill >/dev/null 2>&1 && r="ok" || r="kill command not found"
check "kill command is available" "$r"

command -v pgrep >/dev/null 2>&1 && r="ok" || r="pgrep not found (install procps)"
check "pgrep command is available" "$r"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
