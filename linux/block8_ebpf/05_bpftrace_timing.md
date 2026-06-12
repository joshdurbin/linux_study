# bpftrace Timing and Stack Traces

## Timing with nsecs

`nsecs` is a bpftrace built-in that returns the current monotonic time in nanoseconds. Pairing an entry probe with a return probe lets you measure how long a function takes:

```bash
kprobe:vfs_read    { @start[tid] = nsecs; }
kretprobe:vfs_read { @ns = hist(nsecs - @start[tid]); }
```

## Lesson 7 — vfs_read Latency (Complete Form)

```bash
sudo bpftrace -e '
kprobe:vfs_read {
    @start[tid] = nsecs;
}
kretprobe:vfs_read
/@start[tid]/ {
    @ns[comm] = hist(nsecs - @start[tid]);
    delete(@start[tid]);
}'
```

Three key patterns here:

1. **Thread ID keying** (`@start[tid]`): keying the timestamp map by thread ID rather than PID ensures that concurrent reads from different threads in the same process don't collide.

2. **Entry guard filter** (`/@start[tid]/`): bpftrace may attach after some reads have already entered the kernel. Without this filter, you'd compute `nsecs - 0` for those, producing garbage latency values.

3. **Cleanup** (`delete(@start[tid])`): each completed read must remove its entry from `@start`. Without cleanup, the map grows unboundedly for long-running programs.

## Lesson 8 — Scheduler Tracepoints

The scheduler emits tracepoints when tasks switch:

```bash
sudo bpftrace -e '
tracepoint:sched:sched_switch {
    @[args.prev_comm, args.next_comm] = count();
}'
```

`sched_switch` fires every context switch. `args.prev_comm` is the task going off-CPU; `args.next_comm` is the task coming on-CPU. This reveals which pairs of processes are competing for CPU time.

View all scheduler tracepoints:
```bash
sudo bpftrace -l 'tracepoint:sched:*'
# tracepoint:sched:sched_kthread_stop
# tracepoint:sched:sched_migrate_task
# tracepoint:sched:sched_process_exec
# tracepoint:sched:sched_process_exit
# tracepoint:sched:sched_process_fork
# tracepoint:sched:sched_switch
# tracepoint:sched:sched_wakeup
```

## Lesson 9 — CPU Profiling at 99 Hz

Sample all CPUs 99 times per second and record kernel stack traces:

```bash
sudo bpftrace -e '
profile:hz:99 {
    @[kstack] = count();
}'
```

`profile:hz:99` is a PMU-based timer that fires on all CPUs at ~99 Hz. `kstack` captures the current kernel call stack as a multi-line string. The resulting map shows which kernel code paths were on-CPU most often.

Why 99 Hz, not 100? To avoid lockstep with 100 Hz system timers, which would cause timer-related functions to appear artificially hot.

## Generating Flame Graph Input from bpftrace

```bash
# 1. Sample for 30 seconds
sudo timeout 30 bpftrace -e 'profile:hz:99 { @[kstack, comm] = count(); }' \
    > /tmp/bpftrace_out.txt

# 2. Collapse the bpftrace map output into folded format
# (The bpftrace output format needs custom processing or use -f json)

# Alternative: use the dedicated bpftrace flame graph output
sudo bpftrace -e 'profile:hz:99 { @[kstack, ustack, comm] = count(); }' \
    -o /tmp/profile.bt
```

For clean flame graph generation, bpftrace's `-f json` output format works with `bpftrace-to-flamegraph.sh` from the FlameGraph repo.

## User-Space Stack Traces with ustack

```bash
sudo bpftrace -e '
profile:hz:49 {
    @[ustack, comm] = count();
}'
```

`ustack` captures the user-space call stack. Requires debug symbols in the target binary. For Go binaries, symbols are embedded by default. For C, compile with `-g` or install `debuginfo` packages.

## Combining kstack and ustack

```bash
sudo bpftrace -e '
profile:hz:49 /comm == "nginx"/ {
    @[ustack, kstack] = count();
}'
```

This shows the complete picture: what user-space code (e.g., which Nginx function) triggered what kernel code (e.g., `vfs_read` → `ext4_file_read_iter`).

## Further Reading

- [bpftrace reference guide](https://github.com/bpftrace/bpftrace/blob/master/docs/reference_guide.md) — Documents the `nsecs` and `elapsed` built-ins, the `kstack`/`ustack` stack trace variables, the `profile:hz:N` probe type, and symbol resolution requirements for user-space stacks with debug info.
- [Brendan Gregg: eBPF off-CPU flame graph](https://www.brendangregg.com/blog/2016-01-20/ebpf-offcpu-flame-graph.html) — Shows how to use the `nsecs`-based timing pattern from this lesson to measure off-CPU wait time (I/O, locks, sleep) and generate off-CPU flame graphs alongside CPU flame graphs.
- [FlameGraph repository](https://github.com/brendangregg/FlameGraph) — The `bpftrace-to-flamegraph.sh` script and collapse scripts that convert bpftrace `profile:hz:99` stack output (with `-f json`) into flame graph SVGs.
