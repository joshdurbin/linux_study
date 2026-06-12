# Load Average Deep Dive

Load average is the most-glanced metric on a Linux system and the most misunderstood. This lesson explains exactly what the three numbers mean, when they indicate a problem, and how to distinguish CPU saturation from I/O saturation.

## What Load Average Actually Measures

```bash
uptime
# 14:32:01 up 12 days, 3:14, 1 user, load average: 2.41, 1.87, 1.53
#                                                    1min  5min 15min
```

Load average is an **exponentially weighted moving average** of the number of tasks in two states:
1. **R** — Runnable: actively running on a CPU or waiting in the run queue for one
2. **D** — Uninterruptible sleep: blocked on I/O (disk, network), waiting for a kernel resource

This is Linux-specific. BSD and macOS load averages count only running/runnable tasks (state R). Linux's inclusion of D-state tasks means load average can spike from I/O pressure even when CPUs are idle.

### Reading /proc/loadavg Directly

```bash
cat /proc/loadavg
# 2.41 1.87 1.53 3/412 58291
# │    │    │    │ │    └── last created PID
# │    │    │    │ └── runnable/total threads
# │    │    │    └── running threads / total threads
# 1min 5min 15min
```

The `3/412` field tells you: 3 threads are currently runnable (R state), 412 total threads exist.

## The Exponential Moving Average

Load average is not a simple mean. It's computed every 5 seconds using:

```
load_new = load_old × e^(-5/period) + n × (1 - e^(-5/period))
```

Where `period` is 60s, 300s, or 900s for the three averages, and `n` is the current count of R+D tasks sampled every 5 seconds.

The **1-minute average reacts fastest** to changes; the 15-minute average is slow-moving. Trends matter:

- Load rising: `1min > 5min > 15min` — system getting busier
- Load falling: `1min < 5min < 15min` — system recovering
- Flat: roughly equal — steady state

## Interpreting the Numbers

### CPU Saturation Threshold

A load of **1.0 per core** means 100% CPU utilization with no queue. With 4 cores, a load of 4.0 is fully utilized but not saturated. Above core count = tasks waiting for CPU.

```bash
# Number of logical CPUs (including hyperthreads)
nproc
grep -c "^processor" /proc/cpuinfo   # same thing

# Load relative to core count
CORES=$(nproc)
LOAD=$(awk '{print $1}' /proc/loadavg)
echo "Load per core: $(echo "scale=2; $LOAD / $CORES" | bc)"
```

Rule of thumb: **load/core > 1.0 sustained = CPU saturation**. Brief spikes above 1.0 are normal.

### D-State: The Silent Load Contributor

A process in D state contributes to load average without using CPU. High load with low CPU utilization = I/O bottleneck.

```bash
# Find D-state processes
ps aux | awk '$8 == "D" {print $0}'
ps -eo pid,stat,comm | grep "^[0-9]* *D"

# Quick check: how many D-state processes right now?
ps aux | awk '$8 ~ /^D/ {count++} END {print count+0, "D-state processes"}'
```

D-state processes are typically:
- Waiting on a disk read/write (`await` latency)
- Waiting on NFS mounts (especially if network is slow)
- Waiting on kernel locks (rare, but indicates contention)

## Diagnosing High Load

### Step 1: Is it CPU or I/O?

```bash
# vmstat 1: watch r (run queue) and b (blocked on I/O) columns
vmstat 1 5

# r > 0 consistently = CPU saturation
# b > 0 consistently = I/O saturation
# Both can be elevated simultaneously
```

| `r` | `b` | `wa` | Diagnosis |
|-----|-----|------|-----------|
| High | Low | Low | CPU saturation — processes waiting for CPU |
| Low | High | High | I/O saturation — processes in D state waiting on disk |
| High | High | High | Both — overloaded system |
| Low | Low | Low | Underutilized — load from something else? |

### Step 2: Which Processes?

```bash
# CPU consumers: sort by %CPU
ps aux --sort=-%cpu | head -10

# D-state processes (I/O waiters)
ps -eo pid,stat,wchan,comm | grep " D"
#          wchan = kernel function the process is waiting in
```

### Step 3: Was This a Spike or Sustained?

```bash
# The relationship between the three averages tells you
awk '{
    if ($1 > $2 && $2 > $3) print "Load rising (spike or ongoing increase)"
    else if ($1 < $2 && $2 < $3) print "Load falling (recovering)"
    else print "Load stable or oscillating"
}' /proc/loadavg
```

## Practical Thresholds

| Load / Core Count | Interpretation |
|-------------------|----------------|
| < 0.7 | Healthy — headroom available |
| 0.7 – 1.0 | Good utilization — monitor |
| 1.0 – 1.5 | Lightly saturated — some queue |
| > 2.0 | Saturated — latency visible to users |
| > 5.0 | Severely overloaded |

These are starting points. A latency-sensitive service at 0.8/core may already be unacceptable; a batch system at 2.0/core may be fine.

## Common Misreadings

```bash
# "Load is 8 — that's bad!"
nproc    # 16 cores — 8.0 is 50% utilized, totally fine

# "Load is 0.5 — everything is fine!"
# Not if all processes are in D state waiting on a broken NFS mount
ps aux | awk '$8 ~ /^D/' | wc -l    # might be nonzero

# "Load jumped to 20 suddenly"
# Check: did a cron job or batch script just launch many parallel processes?
ps aux --sort=-%cpu | head -20
```

## Further Reading

- [Brendan Gregg: Linux load averages — solving the mystery](https://www.brendangregg.com/blog/2017-08-08/linux-load-averages.html) — The definitive explanation of why Linux includes D-state tasks in load average (unlike BSD/macOS), with kernel source analysis of the EWMA formula and what each of the three numbers actually measures.
- [proc(5) man page — /proc/loadavg](https://man7.org/linux/man-pages/man5/proc.5.html) — Documents the exact `/proc/loadavg` format including the `running/total threads` field and the precise semantics of the three exponentially weighted moving averages.
- [uptime(1) man page](https://man7.org/linux/man-pages/man1/uptime.1.html) — Short but complete; documents the three load average values and references the `/proc/loadavg` source, confirming that D-state tasks are included in the count.
