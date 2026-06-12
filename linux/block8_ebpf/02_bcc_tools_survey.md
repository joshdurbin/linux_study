# BCC Tools Survey

## What BCC Is

BCC (BPF Compiler Collection) is a toolkit for building efficient kernel tracing and manipulation programs. BCC tools are Python scripts that embed C eBPF programs, compiling them at runtime using LLVM. Each tool targets a specific performance question and outputs a clean answer in seconds.

Install on Ubuntu:
```bash
sudo apt install bpfcc-tools linux-headers-$(uname -r)
# Tools land in /usr/sbin/ as *-bpfcc (e.g., opensnoop-bpfcc)
# Or: pip install bcc  (for the Python bindings)
```

Most tools accept `-d <seconds>` to run for a duration, and many display histograms or live traces.

## Process Tracing

**execsnoop** — trace every new process:
```bash
sudo execsnoop-bpfcc
# PCOMM  PID   PPID  RET ARGS
# bash   1234  1000  0   /bin/bash
```
Catches short-lived processes that disappear before `top` sees them.

**opensnoop** — trace file opens system-wide:
```bash
sudo opensnoop-bpfcc
sudo opensnoop-bpfcc -p 1234     # filter by PID
sudo opensnoop-bpfcc -d 10       # run for 10 seconds
```
Shows PID, process name, file descriptor, return value, and filename.

**bashreadline** — trace bash command-line input:
```bash
sudo bashreadline-bpfcc
# Attaches uprobes to readline() in bash — shows what commands users type
```

## CPU and Scheduling

**profile** — CPU flame graph data (sample stacks at 49 Hz):
```bash
sudo profile-bpfcc -F 49 -d 10 > /tmp/profile.out
# Output: folded stack format suitable for flamegraph.pl
```

**runqlat** — scheduler run queue latency histogram:
```bash
sudo runqlat-bpfcc 1 5     # 1-second intervals, 5 samples
```
Shows how long processes waited in the scheduler queue before getting CPU time. Spikes here indicate CPU saturation or priority inversion.

**cpudist** — on-CPU time distribution per task:
```bash
sudo cpudist-bpfcc
```
Histograms how long processes run before being descheduled. Short runs = scheduler overhead, long runs = potential starvation.

## Memory

**memleak** — detect memory leaks:
```bash
sudo memleak-bpfcc -p 1234 -d 10
```
Tracks `malloc`/`free` pairs. Reports allocations that were never freed, with stack traces.

**slabratetop** — top kernel slab allocations:
```bash
sudo slabratetop-bpfcc 1 10
```
Shows rate of kernel slab cache allocations per second, by cache name.

## I/O

**biolatency** — block I/O latency histogram:
```bash
sudo biolatency-bpfcc
sudo biolatency-bpfcc -d 10 -D   # per-disk breakdown
```
Output is a power-of-2 histogram of I/O latency in microseconds. Reveals latency outliers invisible in averages.

**biotop** — top I/O processes (like top for disk):
```bash
sudo biotop-bpfcc 1 5
```

**fileslower** — slow file reads/writes:
```bash
sudo fileslower-bpfcc 10    # flag operations > 10ms
```

**cachestat** — page cache hit ratio:
```bash
sudo cachestat-bpfcc 1      # per-second stats
# HITS  MISSES  DIRTIES  HITRATIO
# 1024  12      45       98.8%
```
Shows whether your workload is reading from page cache (fast) or disk (slow).

## Networking

**tcpconnect** — trace outbound TCP connections:
```bash
sudo tcpconnect-bpfcc
# PID  COMM  IP  SADDR          DADDR          DPORT
# 1234 curl  4   10.0.0.5       93.184.216.34  443
```

**tcpaccept** — trace inbound TCP connections:
```bash
sudo tcpaccept-bpfcc
```

**tcplife** — log TCP session lifetimes with bytes transferred:
```bash
sudo tcplife-bpfcc
```
Shows duration, sent/received bytes per connection — good for finding chatty or long-lived connections.

**tcpretrans** — log TCP retransmissions:
```bash
sudo tcpretrans-bpfcc
```
Retransmissions indicate network congestion or packet loss.

## Usage Pattern

All BCC tools follow a consistent pattern:
1. They start, print a header, then stream events (or run for `-d` seconds)
2. Many show histograms at the end with `Ctrl-C` or after `-d` expires
3. All require root or `CAP_BPF`/`CAP_SYS_ADMIN`
4. Source is in `/usr/share/bcc/tools/` — readable Python + embedded C

## Further Reading

- [BCC reference guide](https://github.com/iovisor/bcc/blob/master/docs/reference_guide.md) — The authoritative BCC API reference covering kprobes, tracepoints, uprobes, BPF maps, and the Python binding methods used to build every tool surveyed in this lesson.
- [Brendan Gregg: BCC Linux tracing tools](https://www.brendangregg.com/blog/2015-09-22/bcc-linux-tracing-tools.html) — The original blog post introducing BCC's tool collection, with performance overhead measurements and descriptions of `execsnoop`, `biolatency`, `tcpconnect`, and the full tool catalog.
- [BCC tools examples](https://github.com/iovisor/bcc/tree/master/examples) — Python example programs in the BCC repo that demonstrate how each probe type and map type is used, providing the source code backing the tools described in this lesson.
