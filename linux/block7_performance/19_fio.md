# fio — Flexible I/O Tester

`fio` is the industry-standard storage benchmarking tool. It drives the I/O subsystem with precise control over access patterns, block sizes, queue depths, and concurrency — giving you the numbers that actually matter when sizing storage, comparing hardware, or diagnosing performance problems.

## Why Not `dd`?

`dd` is tempting because it's always available, but it has critical blind spots:

| Concern | dd | fio |
|---|---|---|
| Random I/O | No (sequential only) | Yes — configurable |
| Queue depth | Always 1 | Configurable (iodepth) |
| Parallel workers | No | Yes (numjobs) |
| I/O engine | buffered write only | sync, libaio, io_uring, mmap, splice... |
| Metrics | MB/s only | IOPS, bandwidth, full latency percentiles |
| Reproducibility | Depends on cache state | O_DIRECT bypasses page cache |

A `dd` test that writes 1 GB to a buffered file is mostly measuring your page cache write speed. `fio` with `direct=1` talks to the block device layer directly.

## Core Concepts

### I/O Engines (`ioengine=`)

The engine controls *how* I/O is submitted to the kernel:

```
sync         Default. pread()/pwrite() — blocking, one I/O at a time per thread.
psync        preadv()/pwritev() — vectored sync I/O.
libaio       Linux async I/O (io_submit/io_getevents). Requires O_DIRECT.
              Allows queue depth > 1 in a single thread.
io_uring     Newest kernel async I/O interface (Linux 5.1+). Lower overhead than libaio.
              Supports both buffered and direct I/O.
mmap         Files mapped into memory (mmap + memory writes).
splice       splice(2) — zero-copy kernel pipe path.
```

For storage benchmarking, `libaio` or `io_uring` with `direct=1` gives you the most hardware-faithful numbers.

### O_DIRECT vs Buffered

```
direct=0   (default) Writes go to the page cache first.
            Reads may be served from cache entirely.
            Tests your cache + storage together — rarely what you want.

direct=1   O_DIRECT flag. Bypasses page cache.
            Every I/O goes to the block device.
            Tests storage hardware directly.
            Requires block-aligned buffers (fio handles this).
```

Rule: **always use `direct=1` when benchmarking hardware**. Use `direct=0` only when you are intentionally measuring application-level throughput with caching.

### I/O Patterns (`rw=`)

```
read         Sequential read
write        Sequential write
randread     Random read
randwrite    Random write
randrw       Mixed random read + write (use rwmixread= for ratio)
readwrite    Sequential read + write interleaved
rw           Alias for readwrite
trim         TRIM/DISCARD commands (SSDs)
```

### Block Size (`bs=`)

Block size determines how much data each I/O operation transfers:

- **4k** — typical database random I/O (PostgreSQL, MySQL default page = 8k, but 4k common)
- **8k** — Oracle, MySQL default page
- **64k–512k** — large sequential transfers (log files, backups, streaming)
- **1m** — sequential throughput test (maximize MB/s)

Mix sizes with `bssplit=4k/50:64k/50` for realistic database workloads.

### Queue Depth (`iodepth=`)

Queue depth is the number of I/O operations in flight simultaneously. This is the most misunderstood parameter in storage benchmarking.

```
iodepth=1    Submit one I/O, wait for completion, submit next.
              Measures raw latency. IOPS = 1 / latency.

iodepth=32   Up to 32 I/Os in flight at once.
              SSDs are optimized for parallelism — IOPS increases dramatically.
              Measures throughput under concurrency.

iodepth=256  Saturates NVMe drives with many queues.
              Beyond drive's native queue depth, latency rises proportionally.
```

Queue depth matters enormously for NVMe: a drive rated at 100k IOPS at QD=32 might deliver only 10k IOPS at QD=1.

**NVMe drives** have multiple hardware queues (often 32–64 queues × 1024 depth). `numjobs` combined with `iodepth` controls total outstanding I/Os:

```
Total outstanding I/Os = numjobs × iodepth
```

### Parallel Workers (`numjobs=`)

Each job runs as a separate thread or process. Use `numjobs=4` with `iodepth=8` for 32 total in-flight I/Os.

For NVMe, using multiple jobs is essential to exercise multiple hardware queues:
```
numjobs=4 iodepth=16   → 64 in-flight I/Os across 4 kernel queues
```

### ramp_time

```
ramp_time=10s
```

Warm-up period before measurement begins. Essential on SSDs with cache or thermal throttling. Without ramp time, your first 10 seconds may be unrealistically fast (SLC cache on QLC SSDs) or slow (cold start).

### runtime and size

```
runtime=60s        Run for 60 seconds.
time_based=1       Required when using runtime= (don't stop after size is consumed).
size=10g           File/device size to use. For time-based tests, still needs to be set.
```

## Reading fio Output

A typical fio output for a random read test:

```
Jobs: 1 (f=1): [r(1)][100.0%][r=412MiB/s][r=105k IOPS][eta 00m:00s]
read: IOPS=104.9k, BW=410MiB/s (430MB/s)(24.1GiB/60003msec)
  slat (nsec): min=1533, max=231655, avg=2318.42, stdev=1245.30
  clat (usec): min=35, max=3573, avg=93.39, stdev=31.19
  lat (usec): min=37, max=3574, avg=95.71, stdev=31.24
  clat percentiles (usec):
   |  1.00th=[   51],  5.00th=[   60], 10.00th=[   65], 20.00th=[   72],
   | 50.00th=[   86], 75.00th=[  107], 90.00th=[  130], 95.00th=[  145],
   | 99.00th=[  186], 99.50th=[  204], 99.90th=[  273], 99.95th=[  314],
   | 99.99th=[  510]
  bw (  KiB/s): min=382976, max=425984, per=100.00%, avg=420006.4, stdev=7344.82, samples=119
  iops        : min= 93994, max=104448, avg=102979.1, stdev=1800.20, samples=119
```

### Key Metrics

**IOPS** (I/O Operations Per Second)
- The throughput metric for random workloads
- Higher is better
- Meaningful only relative to block size (100k IOPS @ 4k ≠ 100k IOPS @ 512k)

**BW / Bandwidth**
- MB/s or MiB/s throughput
- The throughput metric for sequential workloads
- `BW = IOPS × block_size`

**slat** (Submission latency)
- Time from fio's submit call to kernel accepting the I/O
- Usually nanoseconds; high slat = kernel overhead

**clat** (Completion latency)
- Time from kernel accepting I/O to completion
- This is the "real" storage latency

**lat** = slat + clat (total from app perspective)

**Latency Percentiles — The Critical Ones**

```
p50  (50th percentile)   — median latency, typical case
p99  (99th percentile)   — 1 in 100 I/Os is this slow or worse
p999 (99.9th percentile) — 1 in 1000 I/Os (tail latency — what databases feel)
```

Database applications care intensely about p99 and p999. A drive with excellent p50 but terrible p999 causes sporadic query timeouts. Always examine tail latency, not just averages.

## Job Files

For reproducibility and complex workloads, use job files instead of command-line flags:

```ini
; /root/practice/fio/seq_read.fio
[global]
ioengine=libaio
direct=1
bs=1m
iodepth=32
runtime=30
time_based=1
ramp_time=5
group_reporting=1

[seq-read]
rw=read
filename=/tmp/fio_test
size=512m
```

Run with: `fio seq_read.fio`

Multiple sections define multiple simultaneous jobs:

```ini
[global]
ioengine=libaio
direct=1
runtime=30
time_based=1

[random-readers]
rw=randread
bs=4k
iodepth=16
numjobs=4
filename=/tmp/fio_test
size=1g

[sequential-writer]
rw=write
bs=512k
iodepth=4
numjobs=1
filename=/tmp/fio_test2
size=1g
```

### group_reporting

With `numjobs > 1`, add `group_reporting=1` to aggregate all job stats into a single report instead of per-job noise.

## Common Benchmarking Patterns

### Sequential Read (throughput — NAS, backup, streaming)
```bash
fio --name=seq-read \
    --ioengine=libaio \
    --rw=read \
    --bs=1m \
    --direct=1 \
    --size=1g \
    --numjobs=1 \
    --iodepth=32 \
    --runtime=30 \
    --time_based \
    --filename=/tmp/fio_seq \
    --group_reporting
```

### Random Read (IOPS — database, key-value stores)
```bash
fio --name=rand-read \
    --ioengine=libaio \
    --rw=randread \
    --bs=4k \
    --direct=1 \
    --size=1g \
    --numjobs=4 \
    --iodepth=32 \
    --runtime=60 \
    --time_based \
    --filename=/tmp/fio_rand \
    --group_reporting
```

### Random Write (database write path)
```bash
fio --name=rand-write \
    --ioengine=libaio \
    --rw=randwrite \
    --bs=4k \
    --direct=1 \
    --size=1g \
    --numjobs=4 \
    --iodepth=32 \
    --runtime=60 \
    --time_based \
    --filename=/tmp/fio_rw \
    --group_reporting
```

### Mixed Read/Write (70/30 read/write — OLTP workload)
```bash
fio --name=mixed \
    --ioengine=libaio \
    --rw=randrw \
    --rwmixread=70 \
    --bs=4k \
    --direct=1 \
    --size=1g \
    --numjobs=4 \
    --iodepth=16 \
    --runtime=60 \
    --time_based \
    --filename=/tmp/fio_mixed \
    --group_reporting
```

### Queue Depth Sweep (find device saturation point)
```bash
for qd in 1 2 4 8 16 32 64; do
    echo -n "QD=$qd: "
    fio --name=qd-sweep \
        --ioengine=libaio \
        --rw=randread \
        --bs=4k \
        --direct=1 \
        --size=512m \
        --numjobs=1 \
        --iodepth=$qd \
        --runtime=10 \
        --time_based \
        --filename=/tmp/fio_qd \
        --output-format=terse \
        --group_reporting 2>/dev/null | awk -F';' '{print "IOPS=" $8 " BW=" $6 " lat_avg=" $16 "us"}'
done
```

## Terse Output for Scripting

`--output-format=terse` produces semicolon-delimited output ideal for parsing:

```bash
fio ... --output-format=terse | awk -F';' '{
    print "IOPS=" $8
    print "BW_KiB=" $6
    print "lat_avg_us=" $16
    print "lat_p99_us=" $28
    print "lat_p999_us=" $29
}'
```

Terse format fields (version 3):
- Field 6: bandwidth (KiB/s)
- Field 8: IOPS
- Field 16: lat avg (usec)
- Field 28: lat 99.00th percentile
- Field 29: lat 99.90th percentile

## Common Benchmarking Mistakes

**1. Not using O_DIRECT**
Without `direct=1`, you're benchmarking the page cache, not storage. All writes complete at RAM speed. Results are meaningless for hardware comparison.

**2. File too small to overflow page cache**
If your test file fits in RAM, after the first pass everything is cached. Use `size` larger than available RAM, or use `direct=1`.

**3. Test too short**
SSDs have SLC write caches that deliver burst performance for 5–30 seconds before dropping to sustained rates. Run at least 60 seconds (with `ramp_time=10`).

**4. Testing on a filesystem with only sequential patterns**
OS readahead turns sequential reads into huge streaming prefetches. If you care about database random I/O, always use `randread`/`randwrite`.

**5. Queue depth mismatch**
Reporting "100k IOPS" without stating queue depth is meaningless. QD=1 IOPS vs QD=32 IOPS are completely different metrics.

**6. Forgetting `--time_based`**
Without `time_based=1`, fio stops when the file is consumed, not when `runtime` expires.

## Disk Saturation vs Queue Depth

When a device is saturated, adding more queue depth increases latency proportionally without increasing IOPS:

```
Queue depth 1:   IOPS=10k,  lat=100us   (not saturated)
Queue depth 8:   IOPS=70k,  lat=115us   (approaching saturation)
Queue depth 32:  IOPS=100k, lat=320us   (saturated — latency rising)
Queue depth 128: IOPS=100k, lat=1280us  (same IOPS, much worse latency)
```

This is Little's Law: `IOPS = queue_depth / latency`. At saturation, queue depth and latency rise together while IOPS plateaus.

## io_uring vs libaio

`io_uring` (Linux 5.1+, Ubuntu 20.04+) is the modern replacement for `libaio`:

```
libaio:    Requires O_DIRECT. Separate submission/completion ring.
           Two syscalls per operation (io_submit + io_getevents).

io_uring:  Works with buffered I/O. Shared memory rings — can batch
           submission and completion with zero syscalls (SQPOLL mode).
           Lower overhead at high IOPS.
```

For Ubuntu 24.04 (Linux 6.8+), `ioengine=io_uring` is preferred for new benchmarks.

## Interpreting Results in Context

| Storage Type | Typical Random 4k Read IOPS (QD=32) | Sequential Read |
|---|---|---|
| 7200 RPM HDD | 100–200 | 100–200 MB/s |
| SATA SSD | 80k–100k | 500–560 MB/s |
| NVMe PCIe 3.0 | 300k–700k | 2–3.5 GB/s |
| NVMe PCIe 4.0 | 700k–1M+ | 5–7 GB/s |
| RAM (tmpfs) | Millions | 10–50 GB/s |

Cloud VMs (EBS, GCP PD, Azure Disk) have separate provisioned IOPS limits — always check your volume type's limits before concluding you have a hardware problem.

## JSON Output

For structured reporting in CI/CD:

```bash
fio --name=test ... --output-format=json --output=results.json
```

Then parse with `jq`:
```bash
jq '.jobs[0].read | {iops: .iops, bw_MiB: (.bw / 1024), lat_p99_us: .lat_ns.percentile."99.000000" / 1000}' results.json
```

## Further Reading

- [fio documentation](https://fio.readthedocs.io/en/latest/) — The complete fio manual covering all job file options, I/O engines, output formats, and the `--output-format=terse` field layout used in the scripting section of this lesson.
- [fio(1) man page](https://man7.org/linux/man-pages/man1/fio.1.html) — Quick reference for the most commonly used fio command-line flags and their job file equivalents.
- [Brendan Gregg: Systems Performance (book)](https://www.brendangregg.com/blog/2020-07-15/systems-performance-2nd-edition.html) — The storage benchmarking chapter covers fio methodology, interpreting latency percentiles, Little's Law at saturation, and when to trust vs distrust benchmark results.
- [fio io_uring engine documentation](https://fio.readthedocs.io/en/latest/fio_doc.html#i-o-engine) — Specific documentation for the `io_uring` ioengine, covering `sqthread_poll` mode, registered buffers, and how it differs from `libaio` in the Ubuntu 24.04 environment.
