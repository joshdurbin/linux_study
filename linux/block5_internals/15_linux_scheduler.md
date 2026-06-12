# The Linux CPU Scheduler

The Linux scheduler decides which process runs on which CPU and for how long. Understanding it lets you diagnose CPU saturation, tune latency-sensitive workloads, and reason about run-queue behavior.

## CFS — Completely Fair Scheduler

The default scheduler for normal processes is **CFS** (Completely Fair Scheduler). Its goal: give every runnable process a fair share of CPU time proportional to its weight.

CFS tracks **virtual runtime** (`vruntime`) for each task — the amount of CPU time a task has consumed, normalized by its weight. The task with the smallest `vruntime` runs next. Over time, all tasks converge to the same `vruntime`, achieving fairness.

```
vruntime increases while running.
CFS always picks the task with the smallest vruntime (stored in a red-black tree).
```

CFS does **not** use fixed time slices. Instead, it divides the scheduler period (`sched_latency_ns`, default ~6ms) among all runnable tasks. With 4 runnable tasks, each gets ~1.5ms before yielding.

### Key Scheduler Parameters in /proc/sys/kernel

```bash
cat /proc/sys/kernel/sched_latency_ns       # scheduler period (~6ms)
cat /proc/sys/kernel/sched_min_granularity_ns  # minimum slice per task
cat /proc/sys/kernel/sched_wakeup_granularity_ns  # wakeup preemption threshold
```

## Scheduling Classes

Linux has multiple scheduling classes, evaluated in priority order:

| Class | Policy | Use Case |
|-------|--------|----------|
| `SCHED_FIFO` | Real-time, FIFO | Hard real-time, runs until it yields or sleeps |
| `SCHED_RR` | Real-time, round-robin | Real-time with time slices |
| `SCHED_DEADLINE` | Earliest deadline first | Tasks with explicit deadlines |
| `SCHED_OTHER` | CFS (normal) | Default for all processes |
| `SCHED_BATCH` | CFS variant | Batch/background tasks, less preemptive |
| `SCHED_IDLE` | Very low priority | Only runs when nothing else can |

Real-time processes (`SCHED_FIFO`/`SCHED_RR`) always preempt normal (`SCHED_OTHER`) processes. A runaway `SCHED_FIFO` task can starve the entire system.

## nice and renice — Adjusting CFS Priority

`nice` values range from **-20** (highest priority, more CPU weight) to **+19** (lowest priority, least CPU weight). Default is 0.

```bash
# Start a command with a non-default nice value
nice -n 10 ./cpu_intensive.sh     # lower priority (higher nice)
nice -n -5 ./latency_sensitive    # higher priority (requires root for negative)

# Renice a running process
renice -n 5 -p 1234               # set nice of PID 1234 to +5
renice -n -5 -p 1234              # requires root
sudo renice -n -10 -p 1234

# Renice all processes of a user
renice -n 5 -u nobody

# View current nice value
ps -o pid,ni,comm -p 1234
ps aux | awk '{print $1, $3, $18, $11}' | head    # USER %CPU NI COMMAND
```

Nice maps to CFS weight via a non-linear table. Nice -20 gets ~80× the CPU weight of nice +19. Nice 0 = weight 1024 (the reference).

## chrt — Real-Time Scheduling Policies

`chrt` gets and sets the scheduling policy and priority of a process.

```bash
# Check current scheduling policy of a PID
chrt -p 1234

# Run a command with SCHED_FIFO at real-time priority 50
sudo chrt -f 50 ./rt_task

# Run with SCHED_RR at priority 10
sudo chrt -r 10 ./rt_task

# Change policy of running process
sudo chrt -f -p 50 1234
sudo chrt -o -p 0 1234    # reset to SCHED_OTHER (normal)

# Real-time priorities: 1 (lowest RT) to 99 (highest RT)
# SCHED_OTHER always runs below any real-time task
```

Real-time priorities apply only within the real-time classes — they're distinct from nice values.

## taskset — CPU Affinity

CPU affinity pins a process to specific CPU cores, preventing the scheduler from migrating it.

```bash
# Run a command pinned to CPU 0 only
taskset -c 0 ./program

# Pin to CPUs 0 and 1
taskset -c 0,1 ./program

# Pin to CPUs 0 through 3
taskset -c 0-3 ./program

# Check affinity of a running process
taskset -cp 1234          # shows as list: e.g., "0-3"
taskset -p 1234           # shows as hex bitmask

# Change affinity of a running process
taskset -cp 0 1234        # pin PID 1234 to CPU 0 only
sudo taskset -cp 0-1 1234
```

### Why Pin to a CPU?

- **Cache locality**: a pinned process reuses L1/L2 cache on the same core
- **NUMA**: on multi-socket machines, cross-socket memory access is expensive
- **Interference isolation**: separate latency-sensitive from batch workloads

## Observing the Scheduler

```bash
# Run queue length — r column (block1/06 introduced vmstat)
# also from block7: vmstat is introduced there; here we use /proc directly

# Scheduler stats per process in /proc
cat /proc/1234/sched          # CFS stats: vruntime, nr_switches, load

# System-wide scheduler stats
cat /proc/schedstat           # CPU-level context switch and run-queue stats

# Number of CPUs (affects how to interpret load average)
nproc
cat /proc/cpuinfo | grep "^processor" | wc -l

# Context switches
cat /proc/1234/status | grep ctxt   # voluntary and non-voluntary context switches

# Current scheduling policy of this shell
chrt -p $$
```

## Practical Patterns

```bash
# Deprioritize a batch job so it doesn't starve interactive work
nice -n 19 make -j$(nproc) &

# Run a latency-sensitive process with real-time priority
sudo chrt -f 50 taskset -c 0 ./latency_sensitive_daemon

# Prevent a hot thread from migrating across cores
PID=$(pgrep my_worker)
sudo taskset -cp 2 $PID

# Diagnose CPU saturation: high 'r' value in /proc/loadavg or vmstat
# means tasks are waiting for CPU — see the load average lesson
cat /proc/loadavg
```

## Further Reading

- [Kernel scheduler documentation — kernel.org](https://www.kernel.org/doc/html/latest/scheduler/) — kernel.org scheduler docs covering CFS design, the deadline scheduler, load balancing, energy-aware scheduling, and the `/proc/sys/kernel/sched_*` tunables.
- [sched(7) — man7.org](https://man7.org/linux/man-pages/man7/sched.7.html) — the overview page for all Linux scheduling policies: `SCHED_OTHER` (CFS), `SCHED_FIFO`, `SCHED_RR`, `SCHED_DEADLINE`, `SCHED_BATCH`, `SCHED_IDLE`, the nice-to-weight table, and real-time priority ranges.
- [chrt(1) — man7.org](https://man7.org/linux/man-pages/man1/chrt.1.html) — documents `chrt` flags for setting `SCHED_FIFO`, `SCHED_RR`, `SCHED_DEADLINE`, and resetting to `SCHED_OTHER`, including the `-p` flag for modifying running processes.
- [LWN — CFS scheduler](https://lwn.net/Articles/230975/) — Ingo Molnár's original CFS announcement and Linus's analysis; explains the vruntime model, the red-black tree design, and why CFS replaced the O(1) scheduler.
- [Brendan Gregg — CPU Utilization is Wrong](https://www.brendangregg.com/blog/2017-05-09/cpu-utilization-is-wrong.html) — explains why `%CPU` from `top` and `vmstat` is misleading for modern CPUs with frequency scaling, and how to use hardware performance counters and scheduler stats for accurate analysis.
