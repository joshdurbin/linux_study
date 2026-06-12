# Exercise: The Linux CPU Scheduler

## Setup

```bash
mkdir -p ~/practice/scheduler
```

## Task 1: Inspect CFS Parameters

Read the scheduler tuning parameters from /proc:

```bash
echo "Scheduler latency (ns):"
cat /proc/sys/kernel/sched_latency_ns

echo "Minimum granularity (ns):"
cat /proc/sys/kernel/sched_min_granularity_ns

echo "Wakeup granularity (ns):"
cat /proc/sys/kernel/sched_wakeup_granularity_ns

# How many CPUs does this system have?
nproc
```

## Task 2: nice — Adjust CFS Priority

```bash
# Check the nice value of this shell
ps -o pid,ni,comm -p $$

# Start a background job at low priority (nice +15)
nice -n 15 sleep 120 &
LOW_PID=$!

# Check its nice value
ps -o pid,ni,comm -p $LOW_PID

# Renice it to a slightly higher priority
renice -n 10 -p $LOW_PID

# Confirm the change
ps -o pid,ni,comm -p $LOW_PID

# Clean up
kill $LOW_PID
```

## Task 3: View nice Values Across Processes

```bash
# Show all processes with their nice values
ps -eo pid,ni,comm | sort -k2 -n | head -20

# Your shell's nice value
ps -o pid,ni,comm -p $$
```

## Task 4: chrt — Inspect Scheduling Policies

```bash
# Check this shell's scheduling policy
chrt -p $$

# Check init (PID 1)
chrt -p 1

# Run a command under SCHED_OTHER (normal, explicit)
chrt -o 0 echo "running under SCHED_OTHER"

# Verify the policy of a sleep process
sleep 60 &
SLEEP_PID=$!
chrt -p $SLEEP_PID
kill $SLEEP_PID
```

## Task 5: taskset — CPU Affinity

```bash
# How many CPUs are available?
nproc

# Run a command pinned to CPU 0
taskset -c 0 sleep 60 &
PIN_PID=$!

# Check its CPU affinity
taskset -cp $PIN_PID

# Change affinity to CPU 0 only (already pinned, so no change)
taskset -cp 0 $PIN_PID
taskset -cp $PIN_PID

kill $PIN_PID
```

## Task 6: Inspect Scheduler Stats for a Process

```bash
# Start a background job
sleep 120 &
STATS_PID=$!

# Read its scheduler stats from /proc
cat /proc/$STATS_PID/status | grep -E "ctxt|voluntary"

# Also check its scheduling class
chrt -p $STATS_PID

kill $STATS_PID
```

## Task 7: Write a Script that Deprioritizes Background Work

```bash
cat > ~/practice/scheduler/batch_job.sh << 'EOF'
#!/bin/bash
# Run a CPU-intensive loop at low priority so it doesn't starve other work
nice -n 19 bash -c '
    count=0
    while [ $count -lt 1000000 ]; do
        count=$((count + 1))
    done
    echo "Batch job complete, counted to $count"
'
EOF
chmod +x ~/practice/scheduler/batch_job.sh
bash ~/practice/scheduler/batch_job.sh
```

## Expected Outcome

- `/proc/sys/kernel/sched_latency_ns` is readable
- `nice -n 15 sleep` shows NI=15 in ps output
- `renice` changes the nice value of a running process
- `chrt -p $$` shows SCHED_OTHER policy for a normal shell
- `taskset -cp <pid>` shows the CPU affinity list
- `~/practice/scheduler/batch_job.sh` uses `nice -n 19`
