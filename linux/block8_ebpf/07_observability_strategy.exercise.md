# Observability Strategy — Exercises

Write a detailed comparison and decision guide. Save everything to `~/practice/observability_strategy.txt`.

## Setup

```bash
mkdir -p ~/practice
```

## Task 1 — Tool availability audit

```bash
echo "=== Observability tool availability ===" >> ~/practice/observability_strategy.txt
for tool in strace perf bpftrace opensnoop-bpfcc biolatency-bpfcc tcpconnect-bpfcc trace-cmd; do
    if command -v "$tool" &>/dev/null; then
        version=$("$tool" --version 2>/dev/null | head -1 || echo "version unknown")
        echo "AVAILABLE: $tool ($version)" >> ~/practice/observability_strategy.txt
    else
        echo "MISSING:   $tool" >> ~/practice/observability_strategy.txt
    fi
done
```

## Task 2 — Scenario: "Why is CPU at 100%?"

```bash
cat >> ~/practice/observability_strategy.txt << 'EOF'

=== Scenario 1: CPU at 100% ===

APPROACH 1 — strace (avoid in production):
  Problem: strace stops the process at every syscall — adds 50x overhead
  When to use: Only in dev/test where slowing the process is acceptable
  Command: strace -c -p <PID>   (summary mode reduces overhead somewhat)

APPROACH 2 — perf (sampling, low overhead):
  Overhead: ~1% CPU for 99 Hz sampling
  Command sequence:
    perf record -g -F 99 -p <PID> sleep 30
    perf report --stdio | head -50
    # Or: perf script | stackcollapse-perf.pl | flamegraph.pl > cpu.svg
  What you get: statistical call graph — which functions consume CPU

APPROACH 3 — bpftrace (precise, in-kernel aggregation):
  Overhead: <1% — aggregation happens in kernel
  Command:
    sudo bpftrace -e 'profile:hz:99 /pid == <PID>/ { @[ustack] = count(); }'
  What you get: histogram of user-space stacks — pinpoints hot call paths
  Advantage over perf: can filter, count, and compute stats in kernel;
    output is already aggregated (not raw samples)

DECISION: Use perf for initial investigation (lower setup cost).
Use bpftrace for production (lower overhead, richer filtering).
Never use strace for CPU profiling in production.
EOF
```

## Task 3 — Scenario: "Which files is this process opening in production?"

```bash
cat >> ~/practice/observability_strategy.txt << 'EOF'

=== Scenario 2: Production file open audit ===

APPROACH 1 — strace:
  Command: sudo strace -e openat -s 256 -p <PID>
  Overhead: HIGH — every openat() stops the process
  Acceptable in production? No — can cause request timeouts
  Use case: Dev debugging only

APPROACH 2 — perf trace:
  Command: sudo perf trace -e openat -p <PID>
  Overhead: Low (uses tracepoints, not ptrace)
  Better than strace for production, but still per-event overhead

APPROACH 3 — bpftrace / BCC opensnoop:
  Command: sudo opensnoop-bpfcc -p <PID>
  Or: sudo bpftrace -e 'tracepoint:syscalls:sys_enter_openat /pid==<PID>/ {
      printf("%s\n", str(args.filename)); }'
  Overhead: Near-zero — eBPF runs in kernel, no process interruption
  Acceptable in production? Yes
  Use case: Production file access auditing, security monitoring

DECISION: Use BCC opensnoop or bpftrace in production.
Use strace only if eBPF is unavailable and you can accept the slowdown.
EOF
```

## Task 4 — Scenario: "What is the database I/O latency distribution?"

```bash
cat >> ~/practice/observability_strategy.txt << 'EOF'

=== Scenario 3: I/O latency distribution ===

APPROACH 1 — strace:
  Can see read()/write() calls and timing with -T flag
  Cannot distinguish disk I/O from cached reads
  Overhead: Very high
  Useful? Only for per-call debugging, not distribution

APPROACH 2 — perf:
  perf trace -e block:block_rq_complete
  Low overhead, but raw events — need post-processing for histogram
  perf record + perf script can generate flame graphs showing I/O paths

APPROACH 3 — bpftrace / BCC biolatency:
  Command: sudo biolatency-bpfcc -p <PID>
  Or: sudo bpftrace -e 'tracepoint:block:block_rq_issue { @start[args.sector]=nsecs; }
      tracepoint:block:block_rq_complete /@start[args.sector]/ {
          @us = hist((nsecs-@start[args.sector])/1000);
          delete(@start[args.sector]); }'
  Output: Latency histogram in microseconds — shows tail latency immediately
  Overhead: Near-zero
  Best tool for this scenario

DECISION: bpftrace or BCC biolatency is the only practical tool for
I/O latency distributions. strace and perf can see events but cannot
easily produce histograms without external processing.
EOF
```

## Task 5 — Summary decision table

```bash
cat >> ~/practice/observability_strategy.txt << 'EOF'

=== Observability Tool Decision Matrix ===

QUESTION                          STRACE    PERF      BPFTRACE/eBPF
-----------------------------------------------------------------
Exact syscall arguments?          Best      No        Yes (tracepoint)
CPU profiling?                    No        Best      Very good
Hardware counters (IPC, cache)?   No        Best      No
I/O latency histogram?            Poor      Moderate  Best
File open audit (production)?     Avoid     Moderate  Best
Memory leak detection?            No        No        Best (memleak)
Network connection tracing?       Moderate  Moderate  Best
Overhead in production?           HIGH      Low       Near-zero
Setup complexity?                 Simple    Medium    Medium-High
Kernel version requirement?       Any       Any       >= 4.9

=== Observability Methodology Summary ===

USE METHOD (for resources):
  Per resource: Utilization + Saturation + Errors
  Resources: CPUs, Memory, Disk, Network, FDs

RED METHOD (for services):
  Rate + Errors + Duration per service endpoint

FOUR GOLDEN SIGNALS (Google SRE):
  Latency, Traffic, Errors, Saturation

FIRST 60 SECONDS CHECKLIST:
  uptime → vmstat → mpstat → pidstat → iostat → free → sar → top
EOF
```

## Verification

```bash
grep -cE "strace|perf|bpftrace|eBPF" ~/practice/observability_strategy.txt
echo "tool references found (should be > 10)"
```
