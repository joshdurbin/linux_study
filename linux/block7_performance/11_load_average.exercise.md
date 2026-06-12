# Exercise: Load Average Deep Dive

## Setup

```bash
mkdir -p ~/practice/loadavg
```

## Task 1: Read Load Average

```bash
# Human-readable form
uptime

# Raw values from the kernel
cat /proc/loadavg

# The fields: 1min 5min 15min running/total lastpid
```

Note the three load average values. Are they rising, falling, or stable?

## Task 2: Normalize Against Core Count

```bash
CORES=$(nproc)
echo "Logical CPUs: $CORES"

# Read 1-minute load average
LOAD1=$(awk '{print $1}' /proc/loadavg)
echo "1-min load: $LOAD1"
echo "Load per core: $(awk -v load=$LOAD1 -v cores=$CORES 'BEGIN {printf "%.2f\n", load/cores}')"
```

Is the load per core above or below 1.0?

## Task 3: Identify the Trend

```bash
awk '{
    one=$1; five=$2; fifteen=$3
    if (one > five && five > fifteen) msg="rising"
    else if (one < five && five < fifteen) msg="falling"
    else msg="stable/oscillating"
    printf "Load: %.2f / %.2f / %.2f — %s\n", one, five, fifteen, msg
}' /proc/loadavg
```

## Task 4: Check for D-State Processes

```bash
# Count D-state (uninterruptible sleep) processes
ps aux | awk '$8 ~ /^D/ {count++} END {print count+0, "D-state processes"}'

# Show D-state processes with their wait channel
ps -eo pid,stat,wchan,comm | awk '$2 ~ /^D/ {print}'
```

D-state processes contribute to load average without using CPU.

## Task 5: Observe Load Metrics with vmstat

```bash
# vmstat 1-second intervals, 5 samples
# 'r' = run queue length, 'b' = blocked on I/O
vmstat 1 5
```

Columns to watch:
- `r`: processes waiting for CPU — high `r` = CPU saturation
- `b`: processes in D state — high `b` = I/O saturation
- `wa`: CPU idle but waiting for I/O

## Task 6: Artificially Raise Load and Observe

Generate CPU load and watch the load average climb:

```bash
# Launch background CPU spinners (one per core)
CORES=$(nproc)
echo "Launching $CORES CPU spinners for 15 seconds..."
i=0; while [ $i -lt $CORES ]; do
    (while true; do :; done) &
    i=$((i + 1))
done
SPINNER_PIDS=$(jobs -p)

# Watch load for 10 seconds
for i in 1 2 3 4 5; do
    echo "$(date '+%H:%M:%S') $(cat /proc/loadavg)"
    sleep 2
done

# Stop the spinners
kill $(jobs -p) 2>/dev/null
wait 2>/dev/null
echo "Spinners stopped. Load should fall."
cat /proc/loadavg
```

## Task 7: Write a Load Summary Script

```bash
cat > ~/practice/loadavg/load_summary.sh << 'EOF'
#!/bin/bash
CORES=$(nproc)
read LOAD1 LOAD5 LOAD15 RUNNABLE REST < /proc/loadavg

echo "=== Load Summary ==="
echo "CPUs: $CORES"
echo "Load average: $LOAD1 (1m) / $LOAD5 (5m) / $LOAD15 (15m)"
echo "Per-core 1m: $(awk -v l=$LOAD1 -v c=$CORES 'BEGIN {printf "%.2f", l/c}')"

DCOUNT=$(ps aux | awk '$8 ~ /^D/ {count++} END {print count+0}')
echo "D-state processes: $DCOUNT"

if awk -v l=$LOAD1 -v c=$CORES 'BEGIN {exit (l/c < 1.0)}'; then
    echo "Status: SATURATED (load/core >= 1.0)"
else
    echo "Status: OK"
fi
EOF
chmod +x ~/practice/loadavg/load_summary.sh
bash ~/practice/loadavg/load_summary.sh
```

## Expected Outcome

- `/proc/loadavg` is readable and parseable with `awk`
- `nproc` returns the number of logical CPUs
- `vmstat` shows `r` and `b` columns for CPU and I/O queue depth
- `~/practice/loadavg/load_summary.sh` reads load and core count and classifies the system
