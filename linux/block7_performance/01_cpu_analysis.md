# CPU Analysis

## The USE Method for CPUs

Brendan Gregg's USE method frames every resource in three dimensions:

- **Utilization** — percentage of time the resource is busy (e.g., 85% CPU)
- **Saturation** — work waiting to be processed (e.g., run queue length > 1 per core)
- **Errors** — hardware or software errors (e.g., MCE events in `dmesg`)

Apply USE to each CPU resource before diving into profiling. High utilization alone is not a problem; saturation (run queue backlog) is what causes latency.

## top / htop — CPU Column Reference

```bash
top -b -n 1        # single snapshot, batch mode
htop               # interactive, color-coded
```

The `%Cpu(s)` line in `top` breaks down as:

| Field | Meaning |
|-------|---------|
| `us`  | User space (non-niced) |
| `sy`  | Kernel (system) space |
| `ni`  | User space, niced (lower priority) |
| `id`  | Idle |
| `wa`  | Waiting for I/O — CPU is idle but a task is blocked on disk/network |
| `hi`  | Hardware interrupt handling |
| `si`  | Software interrupt handling |
| `st`  | Steal time — hypervisor gave this vCPU to another VM |

**Load average** (the three numbers in `uptime` or `top` header) represents the average number of runnable + uninterruptible-sleep tasks over 1, 5, and 15 minutes. A load of 1.0 on a single-core machine means 100% utilized with no queue. On an 8-core machine, load of 8.0 is 100% utilized. Load significantly above core count = CPU saturation.

## mpstat — Per-CPU Breakdown

```bash
mpstat -P ALL 1 3      # all CPUs, 1-second interval, 3 samples
mpstat -P 0,1 1        # only CPUs 0 and 1
```

`mpstat` from the `sysstat` package shows per-core utilization. Look for:
- **Uneven distribution**: one core at 100% while others idle suggests single-threaded bottleneck
- **High `%sys`**: kernel overhead, possibly syscall-heavy workload or driver issues
- **High `%iowait`**: I/O bound, investigate with `iostat`

## pidstat — Per-Process CPU

```bash
pidstat -u 1 5         # CPU usage per process, 1s interval, 5 samples
pidstat -u -p 1234 1   # watch specific PID
```

Columns include `%usr`, `%system`, `%CPU` (combined), and `Command`. Use `-t` to also show threads.

## vmstat — System-Wide CPU and Run Queue

```bash
vmstat 1 5             # 1-second intervals, 5 reports
```

Key CPU columns:

| Column | Meaning |
|--------|---------|
| `r`    | Run queue length — processes waiting for CPU |
| `b`    | Blocked processes (waiting on I/O) |
| `us`   | User time |
| `sy`   | System time |
| `id`   | Idle |
| `wa`   | I/O wait |

A persistent `r` value greater than the number of CPUs indicates CPU saturation. The first `vmstat` line is a summary since boot — ignore it and watch subsequent lines.

## Workflow

1. `uptime` — check load average trend
2. `vmstat 1` — is run queue saturated?
3. `mpstat -P ALL 1` — is it one core or all cores?
4. `top` or `pidstat -u 1` — which processes are consuming CPU?
5. `perf top` or `perf record -g` — which functions within those processes?

## Further Reading

- [Brendan Gregg: Linux Performance](https://www.brendangregg.com/linuxperf.html) — The canonical Linux performance analysis page with the full tool map showing where `top`, `mpstat`, `pidstat`, and `vmstat` fit in the CPU analysis workflow.
- [Brendan Gregg: USE Method](https://www.brendangregg.com/usemethod.html) — The original USE method article with the Linux checklist for CPU utilization, saturation (run queue), and error metrics — the framework driving the workflow in this lesson.
- [mpstat(1) man page](https://man7.org/linux/man-pages/man1/mpstat.1.html) — Complete reference for all `mpstat` options including `-P`, `-I`, and output fields (`%usr`, `%sys`, `%iowait`, `%steal`) that identify single-threaded vs multi-core CPU bottlenecks.
- [Julia Evans: How do profilers work?](https://jvns.ca/blog/2018/02/16/profiling-in-python/) — Clear explanation of sampling vs instrumentation profiling, why 99 Hz is used instead of 100 Hz, and how profiler output relates to the CPU utilization numbers in `top`.
- [perf wiki](https://perf.wiki.kernel.org/) — The official perf documentation covering hardware counter events, `perf stat`, `perf record`, and the `perf top` command that is the next step after `pidstat` identifies a process.
