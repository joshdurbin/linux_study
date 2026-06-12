# Memory Analysis

## Key Metrics: Free vs Available

The most important distinction in Linux memory reporting is **free** vs **available**:

- **Free**: bytes not used for anything at all
- **Available**: estimate of memory available for starting new applications — includes reclaimable page cache and slab

On a healthy system `free` is often near zero because the kernel aggressively uses idle RAM as page cache. This is normal and desirable. What matters for capacity is `available`.

## free -h — Understanding the Output

```bash
free -h
```

```
              total        used        free      shared  buff/cache   available
Mem:           15Gi        3.2Gi       200Mi      512Mi      12Gi        11Gi
Swap:          2.0Gi        0B         2.0Gi
```

| Column | Meaning |
|--------|---------|
| `total` | Physical RAM installed |
| `used` | `total - free - buff/cache` — application memory |
| `free` | Completely unused RAM |
| `shared` | tmpfs / shared memory (`/dev/shm`, `POSIX shm`) |
| `buff/cache` | Kernel buffers + page cache (reclaimable) |
| `available` | Estimated usable for new allocations |

Swap usage above zero with available memory depleted signals memory pressure.

## /proc/meminfo Deep Dive

```bash
cat /proc/meminfo
```

Key fields beyond the basics:

| Field | Meaning |
|-------|---------|
| `Dirty` | Pages modified but not yet written to disk |
| `Writeback` | Pages actively being written to disk now |
| `AnonPages` | Anonymous (heap/stack) memory mapped pages |
| `Mapped` | Files mmap'd into process address spaces |
| `Shmem` | Memory used by tmpfs + shared memory |
| `Slab` | Kernel data structure caches (dentries, inodes) |
| `SReclaimable` | Slab portion that can be reclaimed under pressure |
| `SUnreclaim` | Slab that cannot be reclaimed |

High `Dirty` combined with high `wa` CPU time means writes are being throttled by storage.

## vmstat — Memory Columns

```bash
vmstat 1 5
```

| Column | Meaning |
|--------|---------|
| `swpd` | Virtual memory used (swap) |
| `free` | Idle memory |
| `buff` | Memory used as buffers |
| `cache` | Memory used as cache |
| `si` | Memory swapped in from disk per second |
| `so` | Memory swapped out to disk per second |

Non-zero `si`/`so` is the critical signal — active swapping indicates memory saturation, causing severe performance degradation.

## Page Reclaim: kswapd and Direct Reclaim

When available memory drops below a threshold (`/proc/sys/vm/min_free_kbytes`), the kernel has two reclaim paths:

1. **kswapd**: background kernel thread (`kswapd0`, `kswapd1` per NUMA node) that proactively reclaims page cache and anonymous pages
2. **Direct reclaim**: foreground reclaim that stalls the allocating process — visible as high latency

```bash
# Watch kswapd CPU usage
pidstat -p $(pgrep kswapd) 1 5

# Check vmstat si/so for swap activity
vmstat 1 10
```

## OOM Killer Events

When all reclaim paths fail, the Out-Of-Memory killer terminates a process:

```bash
dmesg | grep -i oom
dmesg | grep -i "killed process"
grep -i "out of memory" /var/log/syslog
```

The OOM killer scores each process (visible in `/proc/PID/oom_score`) and kills the highest scorer. Protect critical processes:

```bash
echo -17 > /proc/PID/oom_adj   # legacy
echo -1000 > /proc/PID/oom_score_adj  # modern
```

## Further Reading

- [Brendan Gregg: Linux memory analysis](https://www.brendangregg.com/linuxperf.html#Memory) — The memory section of Brendan Gregg's Linux performance page, with the tool map showing where `free`, `vmstat`, `/proc/meminfo`, and eBPF tools fit in memory analysis.
- [proc(5) man page — /proc/meminfo](https://man7.org/linux/man-pages/man5/proc.5.html) — The canonical reference documenting every `/proc/meminfo` field including `AnonPages`, `Shmem`, `SReclaimable`, `Dirty`, `Writeback`, and the OOM-related fields.
- [free(1) man page](https://man7.org/linux/man-pages/man1/free.1.html) — Documents the `free` command output columns (`total`, `used`, `free`, `available`, `buff/cache`) and the `-h`, `-s`, `-c` options for continuous monitoring.
- [LWN: Memory management — the whole story](https://lwn.net/Articles/619738/) — In-depth LWN article series covering page reclaim, kswapd, the OOM killer scoring algorithm, and the `available` memory estimate formula that `free -h` shows.
