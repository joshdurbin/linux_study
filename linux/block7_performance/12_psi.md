# Pressure Stall Information (PSI)

PSI is a Linux kernel feature (4.20+) that measures the fraction of time tasks are stalled waiting for CPU, memory, or I/O. Unlike load average, PSI tells you **what** is causing stalls and by **how much**, expressed as a percentage of wall-clock time.

## The Problem with Load Average for I/O

Load average counts D-state tasks but gives no insight into:
- How long tasks actually waited
- Whether the stall came from CPU, memory, or I/O
- Whether the resource pressure is brief or sustained

PSI answers all of these.

## /proc/pressure — The PSI Interface

Three files, one per resource:

```bash
cat /proc/pressure/cpu
cat /proc/pressure/memory
cat /proc/pressure/io
```

Each file contains one or two lines with this format:

```
some avg10=0.12 avg60=0.08 avg300=0.03 total=12345678
full avg10=0.00 avg60=0.00 avg300=0.00 total=0
```

## some vs full

| Metric | Definition |
|--------|-----------|
| `some` | At least one task was stalled waiting for this resource |
| `full` | **All** runnable tasks were stalled simultaneously (no work progressed at all) |

`full` is the more severe signal. A `full` stall of 5% means 5% of the time the system was completely blocked — no useful work could proceed.

- **CPU** only has `some` (the CPU metric counts time waiting in the run queue; there's always a task running, so `full` is undefined for CPU)
- **Memory** and **I/O** have both `some` and `full`

## avg10, avg60, avg300

Like load average, PSI uses exponentially weighted moving averages over 10, 60, and 300 seconds. The unit is **percentage of time** (0–100).

```
avg10=2.50   → 2.5% of the last 10 seconds, tasks were stalled on this resource
avg60=1.20   → 1.2% of the last 60 seconds
avg300=0.80  → 0.8% of the last 5 minutes
```

A value of `0.00` means no stalls were observed in that window.

## total

The `total` field is a monotonically increasing count in **microseconds** of accumulated stall time since boot. Useful for computing rates over a precise interval:

```bash
# Sample total stall time, wait 10 seconds, sample again
before=$(awk '/^some/ {print $NF}' /proc/pressure/io | cut -d= -f2)
sleep 10
after=$(awk '/^some/ {print $NF}' /proc/pressure/io | cut -d= -f2)
echo "I/O stall in last 10s: $(( (after - before) / 1000 )) ms"
```

## Reading PSI

```bash
# CPU pressure — is anything waiting for CPU?
cat /proc/pressure/cpu
# some avg10=3.21 avg60=2.15 avg300=1.44 total=987654321
# Interpretation: 3.2% of time in the last 10s, at least one task was waiting for CPU.

# Memory pressure — is anything stalling on memory allocation?
cat /proc/pressure/memory
# some avg10=0.00 avg60=0.00 avg300=0.00 total=0
# full avg10=0.00 avg60=0.00 avg300=0.00 total=0
# Interpretation: no memory pressure at all.

# I/O pressure — is disk I/O causing stalls?
cat /proc/pressure/io
# some avg10=12.45 avg60=8.33 avg300=4.22 total=5432109876
# full avg10=2.10  avg60=1.05 avg300=0.55 total=987654321
# Interpretation: significant I/O pressure; 2.1% of time no task could make progress.
```

## Thresholds for Alerting

These are commonly used starting points:

| Resource | Metric | Threshold | Concern |
|----------|--------|-----------|---------|
| CPU | some avg60 | > 10% | CPU saturation |
| I/O | some avg60 | > 10% | Disk I/O bottleneck |
| I/O | full avg60 | > 1% | Severe I/O stall |
| Memory | full avg60 | > 1% | Memory pressure, possible OOM risk |

`full` memory pressure above 0% is a strong signal — it means all tasks were simultaneously stalled waiting for memory, which typically precedes OOM kills.

## PSI in Practice

```bash
# Quick health check across all three resources
for res in cpu memory io; do
    echo "=== /proc/pressure/$res ==="
    cat /proc/pressure/$res
done

# Extract just the avg10 'some' values for a dashboard line
awk '
/^some/ {
    for (i=1; i<=NF; i++) if ($i ~ /^avg10=/) {split($i, a, "="); print FILENAME": "a[2]}
}' /proc/pressure/cpu /proc/pressure/memory /proc/pressure/io

# Detect if I/O stall is currently high
IO_SOME=$(awk '/^some/ {split($2, a, "="); print a[2]}' /proc/pressure/io)
awk -v val="$IO_SOME" 'BEGIN {
    if (val+0 > 10) print "WARNING: I/O some stall > 10% ("val"%)"
    else print "OK: I/O some stall = "val"%"
}'
```

## PSI and cgroups v2

PSI is also available per-cgroup when using cgroups v2 (introduced in block5/07). Each cgroup exposes:

```bash
cat /sys/fs/cgroup/<cgroup>/cpu.pressure
cat /sys/fs/cgroup/<cgroup>/memory.pressure
cat /sys/fs/cgroup/<cgroup>/io.pressure
```

This lets you measure resource pressure for a specific container or service, not just the whole system.

## Further Reading

- [kernel.org: PSI documentation](https://www.kernel.org/doc/html/latest/accounting/psi.html) — The authoritative kernel documentation for PSI covering the `some`/`full` semantics, the `total` microsecond counter, cgroup v2 integration, and the threshold-based notification interface.
- [Facebook engineering: PSI — how Facebook monitors Linux resource health](https://engineering.fb.com/2018/12/04/production-infrastructure/psi-how-facebook-monitors-linux-resource-health/) — The blog post from PSI's authors describing why load average was insufficient, the design of `some`/`full`, and how Facebook uses PSI thresholds for workload admission control.
- [LWN: Pressure stall information](https://lwn.net/Articles/759658/) — LWN's introduction to PSI, covering the motivation, the metric definitions, and the kernel implementation — good background before diving into the `/proc/pressure/` files directly.
