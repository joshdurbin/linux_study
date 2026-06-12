# Performance and Observability References

The definitive repositories for Linux performance analysis. Brendan Gregg's tooling and methodology are the industry standard — these repos are what block7 and block8 of this course are based on.

---

## perf-tools
**Repo:** https://github.com/brendangregg/perf-tools

Shell scripts and awk wrappers around `perf` and `ftrace`. These are production-safe, low-overhead tools for Linux performance analysis without needing eBPF.

### Tools Directly Relevant to This Course

| Tool | What It Does | Course Connection |
|------|-------------|------------------|
| `execsnoop` | Trace new process executions in real time | block5/03 (execve syscall) |
| `opensnoop` | Trace file open calls | block5/03, block7/04 |
| `iosnoop` | Trace block I/O requests with latency | block7/03 |
| `iolatency` | Block I/O latency histogram | block7/03 |
| `funccount` | Count kernel function calls | block7/07 (ftrace) |
| `funcgraph` | Trace function call graph | block7/07 (ftrace) |
| `kprobe` | Dynamic kprobe tracer | block8 (bpftrace kprobes) |
| `tpoint` | Trace a kernel tracepoint | block7/07 |
| `uprobe` | Dynamic userspace probe | block8 |
| `killsnoop` | Trace kill() calls | block5/04 |
| `tcpretrans` | TCP retransmit tracing | block6, block7/13 |

### Running perf-tools

```bash
git clone https://github.com/brendangregg/perf-tools
cd perf-tools

# Trace all new process executions (useful during incidents)
sudo ./execsnoop

# I/O latency histogram while under load
sudo ./iolatency 1   # histogram per second

# Count which kernel functions are called most
sudo ./funccount 'tcp_*'   # all TCP functions
sudo ./funccount 'ext4_*'  # all ext4 functions

# Trace file opens for a command
sudo ./opensnoop -p $(pgrep nginx)
```

### The "First 60 Seconds" Script

Brendan Gregg's famous checklist is embedded in block7/08. The perf-tools repo contains implementations of the tools behind each step:

```bash
# What the first-60-seconds checklist runs, with perf-tools implementations:
uptime              # load trend
dmesg -T | tail -20 # kernel errors
vmstat 1 5          # CPU/memory/IO summary
mpstat -P ALL 1 3   # per-core CPU
pidstat 1 5         # per-process CPU
sudo ./iolatency 1 5        # perf-tools: I/O latency
sudo ./iosnoop                       # perf-tools: which I/Os are slow
free -h
sar -n DEV 1 3      # network throughput per interface
```

---

## FlameGraph
**Repo:** https://github.com/brendangregg/FlameGraph

The canonical flame graph generator. Block7/06 covers the theory; this is the implementation and a library of example flame graphs showing common patterns.

### Tools in the Repo

```bash
git clone https://github.com/brendangregg/FlameGraph
ls FlameGraph/
# stackcollapse-perf.pl   — convert perf script output to folded stacks
# stackcollapse-bpftrace.pl — convert bpftrace stack output
# stackcollapse-stap.pl   — SystemTap
# stackcollapse-jstack.pl — Java
# flamegraph.pl           — generate SVG from folded stacks
# difffolded.pl           — differential flame graph (before vs after)
```

### Workflows Not in This Course

```bash
# Off-CPU flame graph (time blocked, not running):
# Shows where threads are sleeping — disk I/O, locks, network
sudo offcputime-bpfcc -df -p $(pgrep myapp) 30 | \
    FlameGraph/flamegraph.pl --color=io --title="Off-CPU" > offcpu.svg

# Memory allocation flame graph (where is memory allocated):
sudo stackcount-bpfcc -p $(pgrep myapp) 'kmem:kmalloc' | \
    FlameGraph/stackcollapse-bpftrace.pl | \
    FlameGraph/flamegraph.pl --title="Memory Alloc" > mem.svg

# Differential flame graph: compare two profiles
# (identify what changed between a good and bad deployment)
FlameGraph/difffolded.pl before.folded after.folded | \
    FlameGraph/flamegraph.pl > diff.svg
```

### Reading the Example Library

The repo's `examples/` directory has annotated flame graphs showing:
- CPU-bound application (tall peaks in user code)
- Lock contention (wide flat bars in sync functions)
- System call overhead (large kernel footprint)
- Memory allocator overhead (malloc/jemalloc visible)

Studying these before your first real performance investigation saves hours.

---

## BCC (BPF Compiler Collection)
**Repo:** https://github.com/iovisor/bcc

Block8/02 surveys the BCC tool library. The repo itself is the authoritative reference for what each tool does and how to use it.

### Tools Not Covered in Block8

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `argdist` | Distribution of function argument values | Profile argument patterns |
| `biotop` | Top block I/O by process | Like `iotop` but with more detail |
| `cachestat` | Page cache hit/miss ratio | Diagnose cold-cache issues |
| `cachetop` | Per-process page cache stats | Find which process is thrashing cache |
| `cpudist` | CPU on-time distribution per process | Understand CPU burst patterns |
| `dbslower` | Slow database query tracer | MySQL, PostgreSQL |
| `ext4slower` | Slow ext4 operations | `open`, `read`, `write`, `fsync` > threshold |
| `gethostlatency` | DNS lookup latency | Diagnose slow DNS at the library level |
| `hardirqs` | Hardware IRQ time | Diagnose IRQ storms |
| `softirqs` | Software IRQ time per CPU | Diagnose NET_RX_SOFTIRQ saturation |
| `memleak` | Memory leak detector | Track allocation/free imbalances |
| `mountsnoop` | Trace mount/umount calls | Container and namespace debugging |
| `tcplife` | TCP connection lifecycle with latency | Connection duration and data volume |
| `tcptop` | Top TCP sessions by throughput | Find bandwidth hogs |
| `xfsslower` / `zfsslower` | Filesystem operation latency | Per-filesystem version of ext4slower |

### Writing a BCC Tool (Python API)

```python
#!/usr/bin/env python3
# Minimal BCC tool: count read() calls per process
from bcc import BPF

prog = """
#include <uapi/linux/ptrace.h>
BPF_HASH(counts, u32);

int count_reads(struct pt_regs *ctx) {
    u32 pid = bpf_get_current_pid_tgid() >> 32;
    counts.increment(pid);
    return 0;
}
"""

b = BPF(text=prog)
b.attach_kprobe(event="__x64_sys_read", fn_name="count_reads")

print("Counting read() calls... Ctrl-C to stop")
import time
time.sleep(10)

for pid, count in b["counts"].items():
    print(f"PID {pid.value}: {count.value} reads")
```

---

## bpftrace
**Repo:** https://github.com/bpftrace/bpftrace

Block8/03–06 covers bpftrace in depth. The repo's `tools/` directory contains production-ready one-liners and scripts beyond what the course covers.

### Tools in tools/ Not Covered in This Course

```bash
# From the bpftrace tools/ directory:

# bitesize: I/O request size distribution by process
sudo bpftrace tools/bitesize.bt

# dcsnoop: directory entry cache (dcache) miss rate
sudo bpftrace tools/dcsnoop.bt

# loads: load average over time — like uptime but bpftrace-driven
sudo bpftrace tools/loads.bt

# oomkill: OOM killer events with full context
sudo bpftrace tools/oomkill.bt

# runqlat: run queue (CPU scheduler) latency histogram
sudo bpftrace tools/runqlat.bt
# Directly shows scheduler latency — what you can't see from load average alone

# tcpsynbl: TCP SYN backlog utilization
sudo bpftrace tools/tcpsynbl.bt

# vfsstat: VFS operation counts per second
sudo bpftrace tools/vfsstat.bt
```

### The bpftrace Reference Guide

The repo's `docs/reference_guide.md` is the authoritative bpftrace language reference — more complete than what block8 covers:
- All built-in variables (`@`, `$`, `comm`, `pid`, `nsecs`, `curtask`, `retval`)
- All probe types (`kprobe`, `kretprobe`, `uprobe`, `tracepoint`, `software`, `hardware`, `profile`, `interval`, `BEGIN`, `END`)
- All functions (`printf`, `time`, `join`, `str`, `buf`, `kstack`, `ustack`, `ksym`, `usym`, `ntop`, `exit`, `system`)
- Map types and aggregation (`count`, `sum`, `avg`, `min`, `max`, `hist`, `lhist`, `stats`)

---

## bpf-developer-tutorial
**Repo:** https://github.com/eunomia-bpf/bpf-developer-tutorial

Structured tutorial for writing eBPF programs from scratch using libbpf and CO-RE (Compile Once, Run Everywhere). Picks up where this course's block8 stops.

### What This Adds Beyond block8

Block8 uses bpftrace (high-level scripting) and BCC (Python API). This tutorial covers:
- Writing portable eBPF in C with `libbpf`
- BTF (BPF Type Format) — how CO-RE works
- Skeleton-based workflows (`bpftool gen skeleton`)
- Ring buffers and perf event buffers (output mechanisms)
- BPF maps in depth (hash, array, LRU, per-CPU variants)
- eBPF for security (LSM hooks, seccomp with eBPF)

### Priority Lessons

1. **[Lesson 2: Hello World with libbpf](https://eunomia.dev/tutorials/2-kprobe-unlink/)** — first libbpf program; builds on block8/01 with C instead of Python
2. **[Lesson 7: Capturing Process Execution](https://eunomia.dev/tutorials/7-execsnoop/)** — CO-RE version of execsnoop; shows BTF usage
3. **[Lesson 10: Hardirq/Softirq latency](https://eunomia.dev/tutorials/10-hardirqs/)** — directly extends block7/13 network packet performance
4. **[Lesson 20: tc (Traffic Control) eBPF](https://eunomia.dev/tutorials/20-tc/)** — eBPF programs attached to the network stack; advanced networking
5. **[Lesson 38: LSM hooks for security](https://eunomia.dev/tutorials/38-lsm-connect/)** — eBPF-based security policy; extends block3/04
