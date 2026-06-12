# I/O Analysis

## Block I/O Metrics

Four dimensions describe storage performance:

- **IOPS** (I/O Operations Per Second) — count of read/write operations
- **Throughput** (MB/s) — data transferred per second
- **Latency** (ms) — time from I/O request to completion
- **Utilization** (%) — fraction of time the device is busy

A device can be at 100% utilization at low IOPS if I/Os are sequential and large, or at 100% at high IOPS if I/Os are random and small. Latency is the most user-visible metric.

## iostat -xz 1 — Extended I/O Statistics

```bash
iostat -xz 1 3        # extended stats, hide zero-activity devices, 1s interval, 3 samples
```

Key columns:

| Column | Meaning |
|--------|---------|
| `r/s` | Read operations per second |
| `w/s` | Write operations per second |
| `rkB/s` | Kilobytes read per second |
| `wkB/s` | Kilobytes written per second |
| `await` | Average I/O latency in ms (includes queue time) |
| `r_await` / `w_await` | Per-direction latency |
| `svctm` | Estimated service time (deprecated, unreliable on SSDs) |
| `%util` | Device utilization — time busy handling I/Os |

`%util` near 100% with high `await` = device saturation. On SSDs, `%util` can be high while `await` is still low (parallel internal queues).

## iotop — Per-Process I/O

```bash
sudo iotop -o          # show only processes doing I/O
sudo iotop -b -n 3     # batch mode, 3 iterations
```

`iotop` requires root (or `CAP_NET_ADMIN`). It shows per-process read/write bytes per second, making it easy to find which process is driving I/O.

## /proc/diskstats — Raw Kernel Counters

```bash
cat /proc/diskstats
```

Fields per device (columns 1-14): major, minor, name, reads completed, reads merged, sectors read, ms reading, writes completed, writes merged, sectors written, ms writing, I/Os in progress, ms doing I/O, weighted ms doing I/O.

`iostat` computes its metrics from `/proc/diskstats` deltas. Reading it directly is useful for scripting or when `sysstat` is unavailable.

## lsblk — Block Device Tree

```bash
lsblk                  # show device hierarchy
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,ROTA
```

`ROTA=1` means rotational (HDD); `ROTA=0` means SSD or NVMe. Scheduling and tuning differ significantly between them.

## dd — Basic Throughput Measurement

Measure raw write throughput to a file:

```bash
# Sequential write throughput (direct I/O bypasses page cache)
dd if=/dev/zero of=/tmp/test_write bs=1M count=512 oflag=direct 2>&1

# Sequential read throughput
dd if=/tmp/test_write of=/dev/null bs=1M iflag=direct 2>&1
```

Use `oflag=direct` (`O_DIRECT`) to bypass the page cache and measure actual storage speed. Without it you are measuring memory copy speed.

## Interpreting Results

| Symptom | Likely Cause |
|---------|-------------|
| High `await`, low `%util` | Slow storage or high latency path (NFS, iSCSI) |
| High `%util`, moderate `await` | Saturated device, queue depth too low |
| High `w/s` + high `Dirty` in `/proc/meminfo` | Write-heavy workload, check write-back tuning |
| Spiky `await` | HDD seek time, queue depth, power management |

```bash
# Monitor I/O in real time alongside CPU
iostat -xz 1 | grep -E '(Device|sd|nvme|vd)'
```

## Further Reading

- [Brendan Gregg: Linux disk I/O performance](https://www.brendangregg.com/linuxperf.html#DiskIO) — The disk I/O section of Brendan Gregg's Linux performance page, mapping `iostat`, `iotop`, and eBPF tools to the IOPS/throughput/latency/utilization dimensions introduced in this lesson.
- [iostat(1) man page](https://man7.org/linux/man-pages/man1/iostat.1.html) — Complete reference for all `iostat` output columns (`await`, `r_await`, `w_await`, `%util`, `avgqu-sz`) and the `-x`, `-z`, `-d` options used throughout this lesson.
- [kernel.org: block layer documentation](https://www.kernel.org/doc/html/latest/block/) — Kernel documentation for the block I/O stack covering queue depths, I/O schedulers (`mq-deadline`, `kyber`, `bfq`), and how `/proc/diskstats` counters are incremented.
- [LWN: Block I/O schedulers](https://lwn.net/Articles/720675/) — LWN overview of modern multi-queue block I/O schedulers and how they differ from legacy single-queue schedulers — relevant context for interpreting `await` values on NVMe vs HDD.
