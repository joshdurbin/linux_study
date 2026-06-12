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

[[ -d ~/perflab ]] && r="ok" || r="~/perflab not found"
check "~/perflab exists" "$r"

# Task 1
[[ -f ~/perflab/vmstat.txt ]] && r="ok" || r="vmstat.txt not found"
check "vmstat.txt exists" "$r"

if [[ -f ~/perflab/vmstat.txt ]]; then
  grep -q "swpd\|free\|buff\|cache\|procs" ~/perflab/vmstat.txt && r="ok" || r="vmstat.txt doesn't look like vmstat output"
  check "vmstat.txt looks like vmstat output" "$r"
fi

[[ -f ~/perflab/meminfo.txt ]] && r="ok" || r="meminfo.txt not found"
check "meminfo.txt exists" "$r"

if [[ -f ~/perflab/meminfo.txt ]]; then
  grep -q "MemTotal" ~/perflab/meminfo.txt && r="ok" || r="meminfo.txt missing MemTotal"
  check "meminfo.txt contains MemTotal" "$r"
fi

[[ -f ~/perflab/proc_vmstat.txt ]] && r="ok" || r="proc_vmstat.txt not found"
check "proc_vmstat.txt exists" "$r"

if [[ -f ~/perflab/proc_vmstat.txt ]]; then
  lines=$(wc -l < ~/perflab/proc_vmstat.txt)
  [[ $lines -gt 10 ]] && r="ok" || r="proc_vmstat.txt has only $lines lines (expected many kernel counters)"
  check "proc_vmstat.txt has many kernel stats" "$r"
fi

# Task 2: strace
[[ -f ~/perflab/strace_ls.txt ]] && r="ok" || r="strace_ls.txt not found"
check "strace_ls.txt exists" "$r"

if [[ -f ~/perflab/strace_ls.txt ]]; then
  grep -q "openat\|close\|read\|execve" ~/perflab/strace_ls.txt && r="ok" || r="strace_ls.txt doesn't contain syscall names"
  check "strace_ls.txt contains syscall traces" "$r"
fi

[[ -f ~/perflab/strace_summary.txt ]] && r="ok" || r="strace_summary.txt not found"
check "strace_summary.txt exists" "$r"

if [[ -f ~/perflab/strace_summary.txt ]]; then
  grep -qi "calls\|seconds\|syscall" ~/perflab/strace_summary.txt && r="ok" || r="strace_summary.txt doesn't look like strace -c output"
  check "strace_summary.txt looks like strace -c summary" "$r"
fi

# Task 3: lsof
[[ -f ~/perflab/lsof_sleep.txt ]] && r="ok" || r="lsof_sleep.txt not found"
check "lsof_sleep.txt exists" "$r"

[[ -f ~/perflab/lsof_network.txt ]] && r="ok" || r="lsof_network.txt not found"
check "lsof_network.txt exists" "$r"

[[ -f ~/perflab/shell_fd_count.txt ]] && r="ok" || r="shell_fd_count.txt not found"
check "shell_fd_count.txt exists" "$r"

if [[ -f ~/perflab/shell_fd_count.txt ]]; then
  val=$(tr -d '[:space:]' < ~/perflab/shell_fd_count.txt)
  [[ "$val" =~ ^[0-9]+$ && "$val" -ge 1 ]] && r="ok" || r="shell_fd_count.txt contains '$val' (expected a positive integer)"
  check "shell_fd_count.txt has a valid FD count" "$r"
fi

# Task 4
[[ -f ~/perflab/proc_status.txt ]] && r="ok" || r="proc_status.txt not found"
check "proc_status.txt exists" "$r"

if [[ -f ~/perflab/proc_status.txt ]]; then
  grep -q "VmRSS\|Name\|Pid" ~/perflab/proc_status.txt && r="ok" || r="proc_status.txt doesn't look like /proc/pid/status"
  check "proc_status.txt looks like /proc/pid/status" "$r"
fi

[[ -f ~/perflab/proc_mem.txt ]] && r="ok" || r="proc_mem.txt not found"
check "proc_mem.txt exists" "$r"

if [[ -f ~/perflab/proc_mem.txt ]]; then
  grep -q "VmRSS" ~/perflab/proc_mem.txt && r="ok" || r="proc_mem.txt doesn't contain VmRSS"
  check "proc_mem.txt contains VmRSS" "$r"
fi

[[ -f ~/perflab/proc_fd_count.txt ]] && r="ok" || r="proc_fd_count.txt not found"
check "proc_fd_count.txt exists" "$r"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
