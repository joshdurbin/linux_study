# bpftrace Hello World

## What bpftrace Is

`bpftrace` is a high-level tracing language for eBPF. It uses an awk-like syntax:

```
probe { action }
probe /filter/ { action }
```

It handles compilation, loading, and map management transparently — you write a one-liner and get instant results. bpftrace is ideal for ad-hoc investigation; BCC tools are better for packaged, reusable programs.

Install on Ubuntu 24.04:
```bash
sudo apt install bpftrace
```

> **Container note:** bpftrace requires a privileged container or `CAP_BPF` + `CAP_SYS_ADMIN`.

## Listing Probes

Before writing a probe, find the right hook:

```bash
# List all available probes
sudo bpftrace -l

# Filter by type
sudo bpftrace -l 'kprobe:vfs_*'
sudo bpftrace -l 'tracepoint:syscalls:*'
sudo bpftrace -l 'tracepoint:sched:*'

# Count available probes
sudo bpftrace -l | wc -l
```

Prefer **tracepoints** over **kprobes** when both exist. Tracepoints have a stable ABI; kprobes attach to function names that can change between kernel versions.

## Lesson 1 — Hello World

The `BEGIN` probe fires once when bpftrace starts:

```bash
sudo bpftrace -e 'BEGIN { printf("hello world\n"); }'
```

`END` fires once when bpftrace exits (Ctrl-C or after a timed run). Both are useful for initialization and cleanup/printing.

## Lesson 2 — Built-in Variables

bpftrace provides built-in variables available in any probe:

| Variable | Meaning |
|----------|---------|
| `pid` | Process ID |
| `tid` | Thread ID |
| `uid` | User ID |
| `comm` | Process name (command) |
| `nsecs` | Current time in nanoseconds |
| `elapsed` | ns since bpftrace started |
| `cpu` | CPU number |
| `kstack` | Kernel stack trace |
| `ustack` | User-space stack trace |
| `args` | Tracepoint arguments (as struct) |
| `arg0..argN` | kprobe arguments |
| `retval` | Return value (kretprobe/uretprobe) |

## Lesson 3 — Tracing File Opens

```bash
sudo bpftrace -e '
tracepoint:syscalls:sys_enter_openat {
    printf("%s %s\n", comm, str(args.filename));
}'
```

This fires on every `openat` syscall system-wide. `args.filename` is a pointer to the filename string in the tracepoint's argument struct; `str()` converts the kernel pointer to a string.

To filter to one process:
```bash
sudo bpftrace -e '
tracepoint:syscalls:sys_enter_openat
/comm == "nginx"/ {
    printf("PID %d opened: %s\n", pid, str(args.filename));
}'
```

## Probe Syntax Reference

```
# Kernel function (dynamic, may break between versions)
kprobe:function_name { ... }
kretprobe:function_name { ... }

# Stable tracepoint
tracepoint:subsystem:event_name { ... }

# User-space function (requires path to binary)
uprobe:/bin/bash:readline { ... }
uretprobe:/bin/bash:readline { ... }

# CPU profiling at 99 Hz
profile:hz:99 { ... }

# Interval (run every second)
interval:s:1 { ... }

# Special
BEGIN { ... }
END { ... }
```

## Common Functions

| Function | Description |
|----------|-------------|
| `printf(fmt, ...)` | Print formatted output |
| `str(ptr)` | Convert kernel pointer to string |
| `count()` | Map aggregation: count |
| `sum(n)` | Map aggregation: sum |
| `hist(n)` | Power-of-2 histogram |
| `lhist(n, min, max, step)` | Linear histogram |
| `delete(@map[key])` | Remove map entry |
| `exit()` | Exit bpftrace |
| `time(fmt)` | Print current time |
| `ntop(addr)` | Convert IP address to string |

## Further Reading

- [bpftrace reference guide](https://github.com/bpftrace/bpftrace/blob/master/docs/reference_guide.md) — The authoritative reference for all probe types (`kprobe`, `tracepoint`, `uprobe`, `profile`, `interval`), built-in variables (`pid`, `comm`, `nsecs`, `kstack`), and functions (`printf`, `str`, `count`) introduced in this lesson.
- [bpftrace one-liners tutorial](https://github.com/bpftrace/bpftrace/blob/master/docs/tutorial_one_liners.md) — The official bpftrace one-liner tutorial walking through the same Hello World → tracepoint progression as this lesson, with explanations of each probe and built-in variable.
- [Brendan Gregg: bpftrace](https://www.brendangregg.com/blog/2019-08-19/bpftrace.html) — Brendan Gregg's introduction to bpftrace covering the language design, comparison with DTrace, and the standard tools in `bpftrace/tools/` that extend the patterns from this lesson.
