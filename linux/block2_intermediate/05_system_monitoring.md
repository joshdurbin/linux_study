# System Monitoring

Understanding system resource usage — CPU, memory, disk, I/O — is essential for performance tuning and diagnosing problems.

## top — Live Process Monitor

```bash
top                     # interactive process table
top -b -n 1             # batch mode, one snapshot (scriptable)
top -u alice            # filter to user alice
```

Key `top` keyboard shortcuts:
| Key | Action |
|-----|--------|
| `q` | Quit |
| `M` | Sort by memory |
| `P` | Sort by CPU (default) |
| `T` | Sort by time |
| `1` | Toggle per-CPU breakdown |
| `k` | Kill a process |
| `r` | Renice |
| `f` | Add/remove fields |
| `c` | Toggle full command path |

Header lines explained:
```
load average: 0.15, 0.12, 0.08   # 1min, 5min, 15min avg
Tasks: 120 total, 1 running       # process states
%Cpu(s): 2.3 us, 0.5 sy           # user, system, idle, iowait...
MiB Mem: 7850 total, 5200 free    # memory breakdown
```

Load average: 1.0 per CPU core = 100% utilized. On a 4-core machine, 4.0 = fully loaded.

## htop — Enhanced top

```bash
htop                    # colorized, scrollable, mouse-friendly
htop -u alice           # filter by user
```

F-key actions: F3=search, F5=tree, F9=kill, F10=quit.

## vmstat — Virtual Memory Statistics

```bash
vmstat 1 5              # 5 snapshots, 1 second apart
vmstat -s               # summary statistics
vmstat -d               # disk statistics
```

Output columns:
- **procs**: `r` = running/waiting, `b` = uninterruptible sleep
- **memory**: `swpd`, `free`, `buff`, `cache`
- **swap**: `si` = swap-in, `so` = swap-out (non-zero = bad sign)
- **io**: `bi` = blocks in, `bo` = blocks out
- **cpu**: `us`, `sy`, `id`, `wa` (user, system, idle, iowait)

## iostat — I/O Statistics

```bash
iostat                  # snapshot of CPU and disk I/O
iostat -x 1             # extended stats, refresh every 1s
iostat -d /dev/sda      # specific device
```

Key columns in `-x` mode: `r/s`, `w/s` (reads/writes per sec), `%util` (device utilization).

## free — Memory Usage

```bash
free                    # memory in KB
free -h                 # human-readable (MB/GB)
free -m                 # in megabytes
free -s 2               # refresh every 2 seconds
```

The `available` column is what matters — it includes reclaimable cache.

## uptime — System Uptime and Load

```bash
uptime                  # one-line: time, uptime, load average
uptime -p               # human-readable: "up 3 days, 2 hours"
```

## df — Disk Filesystem Usage

```bash
df -h                   # all filesystems, human-readable
df -h /                 # just root filesystem
df -i                   # inode usage instead of block usage
df -hT                  # include filesystem type
```

Watch for filesystems near 100% — Linux may reserve 5% for root.

## du — Directory Disk Usage

```bash
du -sh /var/log         # total size of /var/log
du -sh *                # size of each item in current directory
du -h --max-depth=1 /   # top-level sizes under /
du -ah /var | sort -rh | head -20  # top 20 largest files/dirs
```

## lsof — List Open Files

```bash
lsof                    # ALL open files (very long list)
lsof -p 1234            # files opened by process 1234
lsof -u alice           # files opened by user alice
lsof /etc/passwd        # who has this file open?
lsof -i                 # network sockets
lsof -i :80             # what process is using port 80?
lsof -i TCP:8080        # TCP connections on port 8080
lsof +D /tmp            # all files under /tmp
```

## /proc — Virtual Filesystem

```bash
cat /proc/cpuinfo           # CPU details
cat /proc/meminfo           # memory details
cat /proc/loadavg           # current load averages
cat /proc/uptime            # seconds since boot
cat /proc/net/tcp           # TCP connections (raw)
ls /proc/1234/              # info about process 1234
cat /proc/1234/cmdline      # command that started process 1234
cat /proc/1234/status       # process status, memory, threads
```

## Further Reading

- [Brendan Gregg — USE Method](https://www.brendangregg.com/usemethod.html) — The Utilization, Saturation, Errors methodology for systematically diagnosing resource bottlenecks across CPU, memory, disk, and network.
- [man7.org — proc(5)](https://man7.org/linux/man-pages/man5/proc.5.html) — Documents every file under `/proc/` that `top`, `vmstat`, `free`, and `ps` read, including `meminfo`, `stat`, `loadavg`, and per-process status.
- [man7.org — vmstat(8)](https://man7.org/linux/man-pages/man8/vmstat.8.html) — Full vmstat column reference including `si`/`so` swap activity, `b` blocked processes, and `wa` I/O wait — key metrics for diagnosing bottlenecks.
- [procps-ng source](https://gitlab.com/procps-ng/procps) — Source for `vmstat`, `free`, `uptime`, `top`, and `ps`; the code shows exactly which `/proc` fields each metric reads.
- [Julia Evans — How perf works (and also hello perf)](https://jvns.ca/blog/2016/03/12/how-does-perf-work-and-also-hello/) — Explains how Linux performance tools access kernel counters, providing context for why `top` and `vmstat` numbers mean what they do.
