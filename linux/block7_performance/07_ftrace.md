# ftrace — Kernel Function Tracing

## What ftrace Is

`ftrace` is the Linux kernel's built-in tracing framework, accessible via a pseudo-filesystem at `/sys/kernel/debug/tracing` (part of `debugfs`). It requires no external tools or kernel modules — it ships in every mainline kernel.

`ftrace` can trace:
- Every kernel function call (function tracer)
- Function call graphs with timing (function_graph tracer)
- Kernel events (scheduler, block I/O, network, interrupts)

> **Container note:** `debugfs` may not be mounted in containers. Check with `ls /sys/kernel/debug/tracing`. To mount: `mount -t debugfs debugfs /sys/kernel/debug`. This may require a privileged container.

## Key Files in /sys/kernel/debug/tracing

```bash
ls /sys/kernel/debug/tracing/
```

| File | Purpose |
|------|---------|
| `current_tracer` | Read/write the active tracer name |
| `tracing_on` | Enable (`echo 1`) or disable (`echo 0`) tracing |
| `trace` | Read the ring buffer contents |
| `trace_pipe` | Stream trace events in real time (blocks until data) |
| `available_tracers` | List of compiled-in tracers |
| `available_events` | All available tracepoints |
| `set_ftrace_filter` | Limit function tracer to specific functions |
| `set_ftrace_pid` | Limit tracing to a specific PID |
| `buffer_size_kb` | Per-CPU ring buffer size |

## Tracers

```bash
cat /sys/kernel/debug/tracing/available_tracers
# nop function function_graph blk mmiotrace ...
```

| Tracer | What it does |
|--------|-------------|
| `nop` | Default — only records enabled events, no function tracing |
| `function` | Records every kernel function call (very high volume) |
| `function_graph` | Records function calls with entry/exit and duration |
| `blk` | Block I/O tracer (used by `blktrace`) |

## Basic ftrace Workflow

```bash
# 1. Check current tracer (should be nop by default)
cat /sys/kernel/debug/tracing/current_tracer

# 2. Enable function_graph tracer
echo function_graph | sudo tee /sys/kernel/debug/tracing/current_tracer

# 3. Optionally limit to one function subtree
echo do_sys_open | sudo tee /sys/kernel/debug/tracing/set_graph_function

# 4. Enable tracing
echo 1 | sudo tee /sys/kernel/debug/tracing/tracing_on

# 5. Run your workload
ls /etc

# 6. Disable tracing
echo 0 | sudo tee /sys/kernel/debug/tracing/tracing_on

# 7. Read results
cat /sys/kernel/debug/tracing/trace | head -50

# 8. Reset to nop when done
echo nop | sudo tee /sys/kernel/debug/tracing/current_tracer
```

## Tracepoints — Kernel Events

Tracepoints are stable instrumentation hooks in the kernel. They are organized by subsystem:

```bash
ls /sys/kernel/debug/tracing/events/
# block  ext4  irq  kmem  net  sched  signal  skb  sock  syscalls  ...

ls /sys/kernel/debug/tracing/events/syscalls/ | head -10
# sys_enter_openat  sys_enter_read  sys_exit_openat ...
```

Enable a tracepoint:
```bash
echo 1 | sudo tee /sys/kernel/debug/tracing/events/syscalls/sys_enter_openat/enable
```

Disable:
```bash
echo 0 | sudo tee /sys/kernel/debug/tracing/events/syscalls/sys_enter_openat/enable
```

## trace-cmd — User-Friendly Frontend

`trace-cmd` wraps the raw debugfs interface:

```bash
sudo trace-cmd record -e sched:sched_switch ls /tmp
sudo trace-cmd report
```

`-e` specifies events (same names as debugfs events directory). Much easier than manual file writes.

## perf-tools (ftrace-based)

Brendan Gregg's `perf-tools` scripts use ftrace internally:

```bash
# Count calls to vfs_read per second
sudo funccount 'vfs_read'

# Histogram of vfs_read latency
sudo funclatency vfs_read

# Trace open() calls system-wide
sudo opensnoop
```

These scripts are in `/usr/share/perf-tools/` on Ubuntu if the `perf-tools-unstable` package is installed.

## Further Reading

- [kernel.org: ftrace documentation](https://www.kernel.org/doc/html/latest/trace/ftrace.html) — The authoritative kernel documentation for ftrace covering all tracers (`function`, `function_graph`, `blk`), the `set_ftrace_filter` syntax, and the ring buffer format.
- [trace-cmd(1) man page](https://man7.org/linux/man-pages/man1/trace-cmd.1.html) — The user-friendly ftrace frontend; documents `trace-cmd record`, `trace-cmd report`, and the event syntax used to avoid writing directly to debugfs files.
- [LWN: Debugging the kernel using ftrace](https://lwn.net/Articles/370423/) — The original LWN article series introducing ftrace, covering the function tracer, function_graph tracer, and tracepoints — written by ftrace author Steven Rostedt.
- [Brendan Gregg: perf kernel line tracing](https://www.brendangregg.com/blog/2014-09-11/perf-kernel-line-tracing.html) — Shows how ftrace and perf complement each other for kernel-level tracing, with examples of using `funcgraph` to trace the I/O path through the kernel.
