# fio Exercises

Work through these tasks to build hands-on familiarity with fio benchmarking. All tests use small sizes and short runtimes suitable for the study container.

## Setup

```bash
mkdir -p ~/practice/fio
cd ~/practice/fio
```

---

## Task 1: Install fio

Install fio using apt.

```bash
apt-get install -y fio
fio --version
```

Verify the version output shows something like `fio-3.x`.

---

## Task 2: Sequential Read Benchmark

Run a sequential read benchmark with a small file size and short runtime. Use buffered I/O for this first test (no `direct=1`) so it completes quickly even in a container.

```bash
fio --name=seq-read \
    --ioengine=sync \
    --rw=read \
    --bs=1m \
    --size=128m \
    --numjobs=1 \
    --iodepth=1 \
    --runtime=10 \
    --time_based \
    --filename=/tmp/fio_seq_test \
    --group_reporting
```

Note the reported bandwidth (BW) in MiB/s and the average latency. This is mostly measuring page cache speed.

---

## Task 3: Random Read Benchmark with O_DIRECT

Now run a random read test that bypasses the page cache. This hits the underlying block device (or its thin-provisioned equivalent in the container).

```bash
fio --name=rand-read \
    --ioengine=sync \
    --rw=randread \
    --bs=4k \
    --direct=1 \
    --size=64m \
    --numjobs=1 \
    --iodepth=1 \
    --runtime=15 \
    --time_based \
    --filename=/tmp/fio_rand_test \
    --group_reporting
```

Compare IOPS here to Task 2. Notice how random 4k reads have far lower bandwidth but the IOPS metric is now the relevant one.

---

## Task 4: Mixed Random Read/Write Workload

Simulate a 70/30 read/write OLTP-style workload:

```bash
fio --name=mixed-rw \
    --ioengine=sync \
    --rw=randrw \
    --rwmixread=70 \
    --bs=4k \
    --size=64m \
    --numjobs=1 \
    --iodepth=1 \
    --runtime=15 \
    --time_based \
    --filename=/tmp/fio_mixed_test \
    --group_reporting
```

Observe that fio reports separate read and write IOPS and latency. The write path will typically show higher latency than reads.

---

## Task 5: Vary Queue Depth and Observe IOPS

Run a queue depth sweep to see how IOPS changes as concurrency increases. Use `ioengine=libaio` which supports `iodepth > 1` properly (requires `direct=1`):

```bash
for qd in 1 4 16; do
    echo "=== Queue Depth: $qd ==="
    fio --name=qd-test \
        --ioengine=libaio \
        --rw=randread \
        --bs=4k \
        --direct=1 \
        --size=64m \
        --numjobs=1 \
        --iodepth=$qd \
        --runtime=8 \
        --time_based \
        --filename=/tmp/fio_qd_test \
        --group_reporting 2>&1 | grep -E 'IOPS|lat '
    echo ""
done
```

In a container backed by a real SSD, IOPS typically increases with queue depth up to a saturation point. In a VM, the storage backend may already be queued at a higher level, so results vary.

---

## Task 6: Write a fio Job File and Run It

Create a job file at `~/practice/fio/rand_read.fio`:

```ini
[global]
ioengine=sync
direct=0
bs=4k
runtime=10
time_based=1
group_reporting=1

[rand-read-job]
rw=randread
filename=/tmp/fio_jobfile_test
size=64m
numjobs=1
iodepth=1
```

Run it:
```bash
fio ~/practice/fio/rand_read.fio
```

Verify fio picks up all parameters from the file.

Now edit the job file to add a second job section for sequential writes:
```ini
[seq-write-job]
rw=write
bs=512k
filename=/tmp/fio_jobfile_seq
size=64m
numjobs=1
iodepth=1
```

Re-run and observe fio running both jobs concurrently with aggregated stats.

---

## Task 7: Write a Storage Benchmark Script

Create `~/practice/fio/bench_storage.sh` that runs three key patterns and summarizes IOPS and average latency for each:

```bash
#!/bin/bash
# bench_storage.sh — summarize key storage patterns using fio

TESTDIR="${1:-/tmp}"
SIZE="64m"
RUNTIME=8

run_bench() {
    local name="$1"
    local rw="$2"
    local bs="$3"
    local extra="$4"

    echo "=== $name ==="
    result=$(fio --name="$name" \
        --ioengine=sync \
        --rw="$rw" \
        --bs="$bs" \
        --size="$SIZE" \
        --numjobs=1 \
        --iodepth=1 \
        --runtime="$RUNTIME" \
        --time_based \
        --filename="$TESTDIR/fio_bench_tmp" \
        --group_reporting \
        --output-format=terse \
        $extra 2>/dev/null)

    iops=$(echo "$result" | awk -F';' '{print $8}')
    bw=$(echo "$result" | awk -F';' '{printf "%.1f MiB/s", $6/1024}')
    lat=$(echo "$result" | awk -F';' '{printf "%.0f us", $16}')

    echo "  IOPS:      ${iops:-N/A}"
    echo "  Bandwidth: ${bw:-N/A}"
    echo "  Avg lat:   ${lat:-N/A}"
    echo ""
}

echo "Storage Benchmark Summary"
echo "========================="
echo "Test dir: $TESTDIR"
echo ""

run_bench "seq-read"   read      1m
run_bench "seq-write"  write     1m
run_bench "rand-read"  randread  4k
run_bench "rand-write" randwrite 4k

rm -f "$TESTDIR/fio_bench_tmp"
echo "Done."
```

Make it executable and run it:
```bash
chmod +x ~/practice/fio/bench_storage.sh
~/practice/fio/bench_storage.sh /tmp
```

---

## Reflection Questions

1. What is the difference between `slat` and `clat` in fio output?
2. Why does IOPS plateau at high queue depth even though latency keeps rising?
3. If you were benchmarking an NVMe drive properly, what `ioengine`, `direct`, `numjobs`, and `iodepth` settings would you use and why?
4. A database reports occasional 200ms query spikes but average latency is 2ms. Which fio latency percentile is most relevant to investigate?
