# Observability Strategy

## The Observability Stack

Modern systems observability is layered. Each layer answers different questions with different costs:

```
┌─────────────────────────────────────┐
│  Metrics (Prometheus, statsd)       │  "Is something wrong?"
├─────────────────────────────────────┤
│  Distributed Tracing (Jaeger, Tempo)│  "Where in the request path?"
├─────────────────────────────────────┤
│  Profiling (perf, pprof, py-spy)    │  "Which function is slow?"
├─────────────────────────────────────┤
│  Kernel Tracing (eBPF, ftrace)      │  "What is the kernel doing?"
└─────────────────────────────────────┘
```

Start at the top (metrics) and descend only as far as needed.

## Choosing the Right Tool

### strace

**Use when:** You need to know exactly what a specific process is doing at the syscall level, and performance doesn't matter.

**Strengths:**
- No setup — available everywhere
- Complete syscall visibility with arguments
- Easy to understand: reads like a log

**Weaknesses:**
- **50x or more slowdown** (ptrace stops process at every syscall)
- Cannot aggregate or summarize without post-processing
- Cannot trace the kernel side of syscalls
- Single process only (unless `-f`)

**Best for:** Debugging "why does this program fail?" or "which files is it reading?" in development or test environments.

```bash
strace -e openat -s 256 myapp       # which files?
strace -T myapp 2>&1 | sort -t'<' -k2 -rn | head  # which syscall is slowest?
strace -c myapp                     # syscall summary
```

### perf

**Use when:** You need statistical CPU profiling with low overhead, or hardware counter analysis.

**Strengths:**
- Very low overhead (sampling, not tracing)
- Hardware performance counter access (cache misses, branch mispredictions, IPC)
- Works across all processes / system-wide
- Call graph profiling for flame graphs

**Weaknesses:**
- Requires elevated privileges
- Sampling misses short-lived events
- `perf.data` is not human-readable without `perf report`
- Limited to CPUs — cannot trace I/O wait or lock contention

**Best for:** Finding CPU bottlenecks in running production systems. Generating flame graphs.

```bash
perf stat -a sleep 10                    # hardware counters system-wide
perf record -g -F 99 -p PID sleep 30    # profile one process
perf script | flamegraph.pl > out.svg   # generate flame graph
```

### bpftrace / eBPF

**Use when:** You need precise, low-overhead tracing of any kernel or user-space event, with the ability to aggregate and compute statistics in the kernel.

**Strengths:**
- **Near-zero overhead** — aggregation happens in-kernel, only results sent to user-space
- Access to any kernel function, syscall, tracepoint, or user-space function
- Histograms, frequency counts, latency measurements in one command
- Does not slow down the traced process (unlike strace)
- Works for I/O wait, lock contention, scheduler events — not just CPU

**Weaknesses:**
- Requires kernel >= 4.9 and privileges
- bpftrace syntax requires learning
- struct access requires knowledge of kernel internals
- kprobes can break between kernel versions (use tracepoints when possible)

**Best for:** Production debugging, latency analysis, security auditing, and any scenario where strace's overhead is unacceptable.

```bash
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_openat { @[comm] = count(); }'  # file opens
sudo bpftrace -e 'kprobe:vfs_read { @start[tid]=nsecs; } kretprobe:vfs_read { @us=hist((nsecs-@start[tid])/1000); delete(@start[tid]); }'
sudo opensnoop-bpfcc       # BCC: openat with zero overhead
```

## Tool Selection Matrix

| Scenario | Best Tool | Why |
|----------|-----------|-----|
| "What syscalls does this app make?" | strace | Complete, easy, dev env |
| "Why is CPU at 100%?" | perf / bpftrace | Low overhead profiling |
| "Which files are being opened in production?" | BCC opensnoop | Zero overhead |
| "What is the I/O latency distribution?" | BCC biolatency | Kernel histogram |
| "Is there lock contention?" | bpftrace off-CPU | Traces wait time |
| "What's causing cache misses?" | perf stat | Hardware counters |
| "Which network calls is this process making?" | strace / BCC tcpconnect | Depends on env |
| "Memory leak?" | BCC memleak | Tracks malloc/free |

## USE vs RED vs Golden Signals

**USE (infrastructure resources):**
- Utilization, Saturation, Errors per resource
- Apply to: CPUs, memory, disks, network interfaces, FDs

**RED (services/endpoints):**
- Rate (requests/sec), Errors (failures/sec), Duration (latency distribution)
- Apply to: HTTP endpoints, gRPC methods, database queries

**Four Golden Signals (Google SRE):**
- Latency, Traffic, Errors, Saturation
- A superset of RED with explicit saturation tracking

Use USE when diagnosing infrastructure. Use RED/Golden Signals when diagnosing services. A full diagnosis usually requires both.

## The First 60 Seconds (Quick Triage)

```bash
uptime          # load average trend
dmesg -T | tail # hardware errors
vmstat 1 5      # CPU, memory, I/O overview
mpstat -P ALL 1 # per-CPU
pidstat 1       # per-process CPU
iostat -xz 1    # disk I/O
free -h         # memory
sar -n DEV 1    # network
top             # process list
```

## Further Reading

- [Brendan Gregg: Linux observability tools](https://www.brendangregg.com/linuxperf.html) — The master tool map showing where strace, perf, BCC, bpftrace, and the "first 60 seconds" commands fit in the observability stack — the visual companion to the tool selection matrix in this lesson.
- [Google SRE Book: Monitoring distributed systems](https://sre.google/sre-book/monitoring-distributed-systems/) — The Google SRE chapter on the Four Golden Signals and monitoring strategy; defines the latency/traffic/errors/saturation framework that complements USE and RED at the service level.
- [Brendan Gregg: USE method](https://www.brendangregg.com/usemethod.html) — The full USE method definition with the Linux resource checklist — the systematic framework underlying the "which tool to reach for first" strategy in this lesson.
- [Grafana: The RED method](https://grafana.com/blog/2018/08/02/the-red-method-how-to-instrument-your-services/) — Defines Rate, Errors, and Duration as the three service-level metrics that complement USE's infrastructure focus — together covering the full observability stack from hardware through application.
