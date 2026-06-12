# Core Linux Tools — Source and Internals

Reading the source of the tools you use daily has a compounding effect: you learn what flags actually do, what the kernel interface looks like, and when a tool's output can be trusted or misleading.

---

## procps-ng
**Repo:** https://github.com/procps-ng/procps

The source for `ps`, `top`, `free`, `vmstat`, `pgrep`, `pkill`, `uptime`, `w`, `watch`, `slabtop`. Every output column you've used is parsed from `/proc`.

### What Reading This Teaches

- Exactly which `/proc` files `ps`, `free`, and `vmstat` read
- Why `top`'s CPU percentages can differ from `ps`'s
- How `pgrep` matches process names (substring vs exact, `/proc/PID/comm` vs `/proc/PID/cmdline`)
- Why `free`'s "available" column differs from "free" (it reads `MemAvailable` from `/proc/meminfo`, which includes reclaimable cache)

### Key Source Files

| Tool | Source File | What to Look For |
|------|------------|-----------------|
| `ps` | `src/ps/display.c` | Column definitions, format specifiers |
| `free` | `src/free.c` | Which `/proc/meminfo` fields map to which columns |
| `vmstat` | `src/vmstat.c` | How `r`, `b`, `si`, `so` are computed |
| `top` | `src/top/top.c` | CPU% calculation, sampling interval |
| `uptime` | `src/uptime.c` | `/proc/loadavg` and `/proc/uptime` parsing |

### Things to Check While Reading

```bash
# Verify free's "available" field source
grep MemAvailable /proc/meminfo

# Compare ps comm vs cmdline (procps uses both)
cat /proc/$$/comm       # short name (15 chars max)
cat /proc/$$/cmdline    # full command line, null-separated
strings /proc/$$/cmdline

# pgrep -x uses exact comm match
pgrep -x bash           # exact
pgrep bash              # substring
```

---

## sysstat
**Repo:** https://github.com/sysstat/sysstat

The source for `iostat`, `mpstat`, `pidstat`, `sar`, `cifsstat`. Every performance metric you've used from this package comes from here.

### What Reading This Teaches

- How `iostat`'s `%util` is calculated (it's not what you think on SSDs)
- How `sar` stores historical data in binary files (the `saXX` files in `/var/log/sysstat/`)
- How `mpstat` reads per-CPU data from `/proc/stat`
- Why `iostat` reports sector sizes and how that affects throughput numbers

### Key Files

| Tool | Source File | What to Look For |
|------|------------|-----------------|
| `iostat` | `iostat.c` | `%util` calculation, `/proc/diskstats` parsing |
| `mpstat` | `mpstat.c` | `/proc/stat` CPU fields |
| `pidstat` | `pidstat.c` | Per-process `/proc/PID/stat` parsing |
| `sar` | `sar.c` | Historical data format, sadc collection |

### The `sar` Historical Collection System

```bash
# Enable sysstat collection (runs sadc every 10 min by default)
sudo systemctl enable --now sysstat

# Query historical CPU data
sar -u                    # today's CPU utilization
sar -u -f /var/log/sysstat/sa$(date +%d)   # today's binary file

# Historical I/O
sar -d 1 3                # disk activity, 1-second intervals, 3 samples
sar -b                    # I/O transfer rate history

# Historical memory
sar -r                    # memory utilization history
```

`sar` is invaluable for post-incident analysis when you need to know what the system was doing 2 hours before an alert fired.

---

## util-linux
**Repo:** https://github.com/util-linux/util-linux

The source for `mount`, `umount`, `lsblk`, `lsns`, `nsenter`, `unshare`, `chrt`, `taskset`, `lscpu`, `dmesg`, `fdisk`, `blkid`, `losetup`, `findmnt`, and dozens more. Many tools from block2, block5, block9 live here.

### Key Tool Sources

| Tool | Why Read It |
|------|------------|
| `lsns` | Shows how namespace metadata is collected from `/proc/PID/ns/` |
| `nsenter` | Illustrates `setns(2)` syscall usage — the primitive behind container exec |
| `unshare` | Illustrates `clone(2)` and `unshare(2)` — how namespaces are created |
| `chrt` | Shows `sched_setscheduler(2)` usage — the syscall behind block5/15 |
| `taskset` | Shows `sched_setaffinity(2)` usage |
| `lscpu` | Shows how CPU topology is read from `/sys/devices/system/cpu/` |
| `dmesg` | Shows `/dev/kmsg` reading and the ring buffer format |
| `findmnt` | Reads `/proc/self/mountinfo` — more detailed than `/etc/mtab` |

### Things to Try

```bash
# lscpu topology — understand NUMA and core layout
lscpu --extended        # per-CPU info: core, socket, NUMA node, online

# findmnt vs mount
mount                   # legacy format
findmnt                 # tree format, reads /proc/self/mountinfo directly

# dmesg with kmsg format
sudo cat /dev/kmsg      # raw kernel message ring buffer
dmesg -w                # follow mode — new kernel messages in real time

# unshare internals: create a new UTS namespace and set a hostname
sudo unshare --uts bash -c 'hostname myfake; hostname'
hostname    # still the original — the change was isolated
```

---

## strace
**Repo:** https://github.com/strace/strace

The source for the `strace` you've used throughout this course (block5/03 and block7/04). Understanding how strace works explains its overhead and its limitations.

### How strace Works

strace uses `ptrace(2)` to intercept syscalls:

1. Attaches to the target process with `ptrace(PTRACE_ATTACH, pid, ...)`
2. Sets `PTRACE_O_TRACESYSGOOD` to receive SIGTRAP on each syscall entry and exit
3. Reads syscall number and arguments from the process's registers via `ptrace(PTRACE_GETREGS, ...)`
4. Formats and prints the syscall, then resumes the process

This means **every syscall stops the process twice** (entry + exit). High-syscall-rate code can be 5–100× slower under strace. For production tracing use `perf trace` or bpftrace instead.

### Key Source Files

| File | What It Shows |
|------|--------------|
| `strace.c` | Main attach/detach loop, ptrace calls |
| `syscall.c` | Syscall number to name mapping, argument decoding |
| `net.c` | How socket-related syscalls are decoded |
| `mem.c` | How mmap/mprotect arguments are decoded |

### strace Alternatives When Overhead Matters

```bash
# perf trace: uses tracepoints instead of ptrace — much lower overhead
perf trace -p 1234                   # trace syscalls for a PID
perf trace -e open,read,write ls /tmp

# bpftrace: zero-copy, in-kernel aggregation — near-zero overhead
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_read { @[comm] = count(); }'

# Comparing overhead:
# ptrace (strace): 5–100× slowdown per-process
# perf trace:      ~2–5% overhead system-wide
# bpftrace:        <1% overhead
```
