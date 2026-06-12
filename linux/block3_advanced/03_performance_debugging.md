# Performance Debugging

When a system is slow or misbehaving, a structured approach — from high-level metrics to low-level system call tracing — helps pinpoint the cause quickly.

## The USE Method

For each resource (CPU, memory, disk, network):
- **Utilization**: how busy is it?
- **Saturation**: is work queued because it's overloaded?
- **Errors**: any error events?

Start with `uptime` (load), `vmstat` (CPU/memory/swap), `iostat` (disk), then drill down.

## strace — System Call Tracer

```bash
strace command                      # trace system calls of a new process
strace -p 1234                      # attach to a running process
strace -e trace=open,read,write cmd # filter to specific syscalls
strace -e trace=network cmd         # network-related syscalls only
strace -e trace=file cmd            # file-related syscalls
strace -c command                   # summary: count and time syscalls
strace -T command                   # show time spent in each syscall
strace -o trace.txt command         # write to file
strace -f command                   # follow child processes (fork)
strace -s 256 command               # increase string size in output (default 32)
```

Reading `strace` output:
```
openat(AT_FDCWD, "/etc/passwd", O_RDONLY) = 3
read(3, "root:x:0:0:root:/root:/bin/bash\n", 4096) = 32
close(3) = 0
```
The return value is after `=`. `-1` means error; `errno` gives the reason.

## lsof — Open Files and Sockets

```bash
lsof -p 1234                  # all files opened by process 1234
lsof -i                       # all network sockets
lsof -i :8080                 # who is using port 8080?
lsof -i TCP:80                # TCP connections on port 80
lsof -u alice                 # files opened by user alice
lsof /var/log/syslog          # which processes have this file open?
lsof +D /tmp                  # all files under /tmp
lsof -n -P -i TCP -s TCP:ESTABLISHED  # established TCP connections
```

## vmstat — Detailed System Stats

```bash
vmstat 1                  # 1-second intervals (Ctrl-C to stop)
vmstat 1 10               # 10 samples, 1 second apart
vmstat -s                 # summary of memory and I/O stats
```

Key columns to watch:
- `r` (run queue): consistently > number of CPUs = CPU saturation
- `b` (blocked): stuck in uninterruptible I/O
- `si`/`so` (swap in/out): any non-zero = memory pressure
- `wa` (CPU iowait): disk I/O is the bottleneck if consistently high
- `us`/`sy`: user space vs kernel time

## perf stat — Hardware Performance Counters

```bash
perf stat command                      # count CPU events
perf stat -a sleep 5                   # system-wide 5-second profile
perf stat -e cache-misses,cycles cmd   # specific events
perf record -g command                 # record with call graph
perf report                            # interactive flame-like report
```

Common events: `cycles`, `instructions`, `cache-misses`, `cache-references`, `branch-misses`.

## sar — System Activity Reporter

```bash
sar 1 5                    # CPU usage, 5 samples, 1 second apart
sar -r 1 5                 # memory stats
sar -d 1 5                 # disk I/O
sar -n DEV 1 5             # network interface stats
sar -u ALL 1 5             # all CPU fields
sar -f /var/log/sysstat/sa01  # read historical data
```

`sar` is part of `sysstat` package. If historical data collection is enabled, it logs every 10 minutes.

## /proc for Performance Data

```bash
cat /proc/meminfo           # detailed memory breakdown
cat /proc/vmstat            # VM statistics counter
cat /proc/diskstats         # raw disk I/O counters
cat /proc/net/dev           # network interface statistics
cat /proc/interrupts        # interrupt counts per CPU

# For a specific process
cat /proc/1234/status       # memory, threads, state
cat /proc/1234/io           # I/O counters
cat /proc/1234/maps         # memory map
cat /proc/1234/fd/          # open file descriptors
ls -la /proc/1234/fd | wc -l  # how many FDs is this process using?
```

## Practical Debug Workflow

```bash
# 1. Is it CPU, memory, or I/O?
vmstat 1 5

# 2. Which process?
top (sort by CPU with P, sort by mem with M)

# 3. What is it doing?
strace -p <PID> -c -e trace=all  # 5 seconds, then Ctrl-C for summary

# 4. What files/ports?
lsof -p <PID>

# 5. Is it leaking FDs?
ls /proc/<PID>/fd | wc -l

# 6. Memory leak?
while true; do
  awk '/VmRSS/{print $2}' /proc/<PID>/status
  sleep 2
done
```

## Further Reading

- [Brendan Gregg — Linux Performance](https://www.brendangregg.com/linuxperf.html) — the definitive Linux performance resource: per-subsystem tool maps, methodologies, and deep dives into `perf`, `strace`, `vmstat`, `sar`, and more, by the author of the USE method.
- [The USE Method](https://www.brendangregg.com/usemethod.html) — Brendan Gregg's methodology applied to Linux: per-resource checklists for CPU, memory, disk, and network saturation analysis — exactly what this lesson's workflow implements.
- [strace(1) — man7.org](https://man7.org/linux/man-pages/man1/strace.1.html) — complete reference for every `strace` flag: `-e trace=`, `-T`, `-c`, `-f`, `-s`, and how to interpret the return values and errno codes in its output.
- [LWN — The perf tool](https://lwn.net/Articles/551539/) — introduction to the `perf` subsystem covering hardware performance counters, `perf stat`, `perf record`, and the event types that underlie `perf report`.
- [perf Examples — Brendan Gregg](https://www.brendangregg.com/perf.html) — practical `perf` cookbook covering CPU profiling, cache analysis, `perf stat` one-liners, and annotated flame graph generation from `perf record -g` data.
