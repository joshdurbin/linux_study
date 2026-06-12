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

[[ -d ~/monitorlab ]] && r="ok" || r="~/monitorlab not found"
check "~/monitorlab exists" "$r"

# Task 1
[[ -f ~/monitorlab/memory.txt ]] && r="ok" || r="memory.txt not found"
check "memory.txt exists" "$r"

if [[ -f ~/monitorlab/memory.txt ]]; then
  grep -qi "mem\|swap" ~/monitorlab/memory.txt && r="ok" || r="memory.txt doesn't look like free output"
  check "memory.txt looks like free output" "$r"
fi

[[ -f ~/monitorlab/uptime.txt ]] && r="ok" || r="uptime.txt not found"
check "uptime.txt exists" "$r"

if [[ -f ~/monitorlab/uptime.txt ]]; then
  grep -q "load\|up" ~/monitorlab/uptime.txt && r="ok" || r="uptime.txt doesn't look like uptime output"
  check "uptime.txt contains load/up info" "$r"
fi

[[ -f ~/monitorlab/loadavg.txt ]] && r="ok" || r="loadavg.txt not found"
check "loadavg.txt exists" "$r"

if [[ -f ~/monitorlab/loadavg.txt ]]; then
  grep -qE '^[0-9]+\.' ~/monitorlab/loadavg.txt && r="ok" || r="loadavg.txt doesn't start with a load average number"
  check "loadavg.txt has numeric load average" "$r"
fi

# Task 2
[[ -f ~/monitorlab/disk_usage.txt ]] && r="ok" || r="disk_usage.txt not found"
check "disk_usage.txt exists" "$r"

if [[ -f ~/monitorlab/disk_usage.txt ]]; then
  grep -q "Filesystem\|/" ~/monitorlab/disk_usage.txt && r="ok" || r="disk_usage.txt doesn't look like df output"
  check "disk_usage.txt looks like df output" "$r"
fi

[[ -f ~/monitorlab/dir_sizes.txt ]] && r="ok" || r="dir_sizes.txt not found"
check "dir_sizes.txt exists" "$r"

[[ -f ~/monitorlab/largest_binaries.txt ]] && r="ok" || r="largest_binaries.txt not found"
check "largest_binaries.txt exists" "$r"

if [[ -f ~/monitorlab/largest_binaries.txt ]]; then
  lines=$(wc -l < ~/monitorlab/largest_binaries.txt)
  [[ $lines -ge 3 ]] && r="ok" || r="largest_binaries.txt has only $lines lines (expected 5)"
  check "largest_binaries.txt has 3+ entries" "$r"
fi

# Task 3
[[ -f ~/monitorlab/top_snapshot.txt ]] && r="ok" || r="top_snapshot.txt not found"
check "top_snapshot.txt exists" "$r"

if [[ -f ~/monitorlab/top_snapshot.txt ]]; then
  grep -qi "cpu\|mem\|tasks" ~/monitorlab/top_snapshot.txt && r="ok" || r="top_snapshot.txt doesn't look like top output"
  check "top_snapshot.txt looks like top output" "$r"
fi

[[ -f ~/monitorlab/process_list.txt ]] && r="ok" || r="process_list.txt not found"
check "process_list.txt exists" "$r"

# Task 4
[[ -f ~/monitorlab/meminfo.txt ]] && r="ok" || r="meminfo.txt not found"
check "meminfo.txt exists" "$r"

if [[ -f ~/monitorlab/meminfo.txt ]]; then
  grep -q "MemTotal" ~/monitorlab/meminfo.txt && r="ok" || r="meminfo.txt doesn't contain MemTotal"
  check "meminfo.txt contains MemTotal" "$r"
fi

[[ -f ~/monitorlab/mem_summary.txt ]] && r="ok" || r="mem_summary.txt not found"
check "mem_summary.txt exists" "$r"

if [[ -f ~/monitorlab/mem_summary.txt ]]; then
  grep -q "MemTotal" ~/monitorlab/mem_summary.txt && r="ok" || r="mem_summary.txt missing MemTotal"
  check "mem_summary.txt has MemTotal" "$r"
  grep -q "MemFree" ~/monitorlab/mem_summary.txt && r="ok" || r="mem_summary.txt missing MemFree"
  check "mem_summary.txt has MemFree" "$r"
  grep -q "MemAvailable" ~/monitorlab/mem_summary.txt && r="ok" || r="mem_summary.txt missing MemAvailable"
  check "mem_summary.txt has MemAvailable" "$r"
fi

[[ -f ~/monitorlab/cpu_count.txt ]] && r="ok" || r="cpu_count.txt not found"
check "cpu_count.txt exists" "$r"

if [[ -f ~/monitorlab/cpu_count.txt ]]; then
  val=$(tr -d '[:space:]' < ~/monitorlab/cpu_count.txt)
  [[ "$val" =~ ^[0-9]+$ && "$val" -ge 1 ]] && r="ok" || r="cpu_count.txt contains '$val' (expected a positive integer)"
  check "cpu_count.txt has a valid CPU count" "$r"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
