# bpftrace Timing — Exercises

> **Container note:** bpftrace requires a privileged container. Document the programs if unavailable.

Complete these tasks. Record findings in `~/practice/bpftrace_timing.txt`.

## Setup

```bash
mkdir -p ~/practice
```

## Task 1 — vfs_read latency probe (run or document)

```bash
echo "=== Lesson 7: vfs_read latency ===" >> ~/practice/bpftrace_timing.txt

if command -v bpftrace &>/dev/null; then
    echo "Running vfs_read latency probe for 5 seconds..." >> ~/practice/bpftrace_timing.txt
    sudo timeout 5 bpftrace -e '
kprobe:vfs_read { @start[tid] = nsecs; }
kretprobe:vfs_read /@start[tid]/ {
    @ns[comm] = hist(nsecs - @start[tid]);
    delete(@start[tid]);
}' 2>/dev/null >> ~/practice/bpftrace_timing.txt || true
else
    cat >> ~/practice/bpftrace_timing.txt << 'EOF'
Command:
  sudo bpftrace -e '
  kprobe:vfs_read { @start[tid] = nsecs; }
  kretprobe:vfs_read /@start[tid]/ {
      @ns[comm] = hist(nsecs - @start[tid]);
      delete(@start[tid]);
  }'

Three critical patterns:
  1. @start[tid] = nsecs      - key by thread ID to handle concurrent reads
  2. /@start[tid]/            - guard: skip if we missed the entry probe
  3. delete(@start[tid])      - cleanup: prevent map from growing unboundedly

Expected output (@ns histograms per process):
  @ns[nginx]:
  [1K, 2K)      45 |@@@@@@@@@@          |
  [2K, 4K)      89 |@@@@@@@@@@@@@@@@@@  |
  [4K, 8K)      23 |@@@@@               |
  [8K, 16K)      4 |                    |
EOF
fi
```

## Task 2 — CPU profiling probe (run or document)

```bash
echo "" >> ~/practice/bpftrace_timing.txt
echo "=== Lesson 9: CPU profiling at 99 Hz ===" >> ~/practice/bpftrace_timing.txt

if command -v bpftrace &>/dev/null; then
    echo "Running CPU profiler for 5 seconds..." >> ~/practice/bpftrace_timing.txt
    sudo timeout 5 bpftrace -e 'profile:hz:99 { @[kstack] = count(); }' \
        2>/dev/null | head -40 >> ~/practice/bpftrace_timing.txt || true
else
    cat >> ~/practice/bpftrace_timing.txt << 'EOF'
Command:
  sudo bpftrace -e 'profile:hz:99 { @[kstack] = count(); }'

How it works:
  - profile:hz:99 is a PMU timer firing at 99 Hz on ALL CPUs simultaneously
  - kstack captures the current kernel call stack (multi-line string)
  - @[kstack] = count() accumulates how often each stack appears
  - On exit, maps are printed sorted by count (hottest stacks last)

Why 99 Hz, not 100?
  To avoid lockstep with the 100 Hz kernel scheduler tick, which would
  make timer-related code appear artificially hot in the profile.

To generate user+kernel stacks for a specific process:
  sudo bpftrace -e '
  profile:hz:49 /comm == "myapp"/ {
      @[ustack, kstack] = count();
  }'
EOF
fi
```

## Task 3 — Scheduler tracepoints (document)

```bash
echo "" >> ~/practice/bpftrace_timing.txt
echo "=== Lesson 8: scheduler context switches ===" >> ~/practice/bpftrace_timing.txt
cat >> ~/practice/bpftrace_timing.txt << 'EOF'
Command:
  sudo bpftrace -e '
  tracepoint:sched:sched_switch {
      @[args.prev_comm, args.next_comm] = count();
  }'

What it shows:
  - Every context switch — prev_comm going off-CPU, next_comm coming on
  - Reveals which process pairs compete for CPU
  - High counts between a single pair = lock contention or shared resource

Other useful scheduler tracepoints:
  sched:sched_wakeup        - task woken from sleep (latency start)
  sched:sched_wakeup_new    - new task woken for first time
  sched:sched_process_fork  - fork() called
  sched:sched_process_exec  - exec() called
  sched:sched_process_exit  - process exited

Run queue latency (time from wakeup to actually running):
  sudo bpftrace -e '
  tracepoint:sched:sched_wakeup,
  tracepoint:sched:sched_wakeup_new { @start[args.pid] = nsecs; }
  tracepoint:sched:sched_switch {
      if (@start[args.next_pid]) {
          @runq_lat = hist(nsecs - @start[args.next_pid]);
          delete(@start[args.next_pid]);
      }
  }'
EOF
```

## Task 4 — Flame graph from bpftrace (workflow)

```bash
cat >> ~/practice/bpftrace_timing.txt << 'EOF'

=== Flame graph from bpftrace profiling ===
# Full pipeline:
# 1. Profile:
#    sudo timeout 30 bpftrace -e 'profile:hz:99 { @[kstack, comm] = count(); }' \
#        > /tmp/bpftrace_profile.txt
#
# 2. Convert to folded format (bpftrace output is already close to folded):
#    awk '/^@\[/{stack=$0; getline; print stack, $1}' /tmp/bpftrace_profile.txt \
#        | sed 's/@\[//;s/\]//' > /tmp/folded.txt
#
# 3. Render:
#    flamegraph.pl /tmp/folded.txt > flamegraph.svg
#
# Alternative: use bpftrace -f json output with jq preprocessing
EOF
```

## Verification

```bash
grep -qi "profile\|kstack\|nsecs" ~/practice/bpftrace_timing.txt
echo "Timing concepts found in notes"
```
