# Exercise: Job Control

## Setup

```bash
mkdir -p ~/practice/jobs
```

## Task 1: Background Jobs and $!

```bash
# Start a background job and capture its PID
sleep 60 &
BG_PID=$!
echo "Background PID: $BG_PID"

# Verify it's running using ps (from block1/06)
ps -p $BG_PID

# Check the jobs list
jobs
```

## Task 2: Job Specifications

Start several jobs and practice referencing them:

```bash
sleep 100 &    # job [1]
sleep 200 &    # job [2]
sleep 300 &    # job [3]
jobs

# Kill job 2 by job spec
kill %2
jobs

# Kill the rest
kill %1 %3
jobs
```

## Task 3: wait — Collect Background Exit Codes

```bash
# A job that succeeds
true &
p1=$!

# A job that fails
false &
p2=$!

wait $p1; echo "true job exited: $?"    # expect 0
wait $p2; echo "false job exited: $?"   # expect 1
```

Now write a script that runs two background sleeps and waits for both:

```bash
cat > ~/practice/jobs/wait_demo.sh << 'EOF'
#!/bin/bash
sleep 1 &
PID1=$!
sleep 2 &
PID2=$!

echo "Waiting for both jobs..."
wait $PID1
echo "Job 1 done: $?"
wait $PID2
echo "Job 2 done: $?"
echo "All jobs complete"
EOF
chmod +x ~/practice/jobs/wait_demo.sh
bash ~/practice/jobs/wait_demo.sh
```

## Task 4: disown — Detach from Shell

```bash
# Start a background job
sleep 1000 &
DETACH_PID=$!
echo "PID before disown: $DETACH_PID"

# Confirm it's in the job table
jobs

# Disown it — removes from job table
disown %1
jobs    # should be empty

# Confirm the process is still running via ps
ps -p $DETACH_PID
```

## Task 5: Parallel Jobs with Error Detection

```bash
cat > ~/practice/jobs/parallel.sh << 'EOF'
#!/bin/bash
# Run three jobs in parallel and check if any failed
true  & pids=($!)
false & pids+=($!)
true  & pids+=($!)

failed=0
for pid in "${pids[@]}"; do
    wait "$pid" || failed=1
done

if [ $failed -eq 0 ]; then
    echo "All jobs succeeded"
else
    echo "At least one job failed"
fi
EOF
chmod +x ~/practice/jobs/parallel.sh
bash ~/practice/jobs/parallel.sh
```

Expected output: `At least one job failed` (because `false` exits 1).

## Task 6: nohup vs disown

```bash
# nohup: immunity set before process starts, output goes to nohup.out
nohup sleep 500 > /tmp/nohup_test.log 2>&1 &
NOHUP_PID=$!
echo "nohup PID: $NOHUP_PID"
ps -p $NOHUP_PID

# disown: remove already-running job from job table
sleep 500 &
DISOWN_PID=$!
disown
ps -p $DISOWN_PID    # still running

# Cleanup
kill $NOHUP_PID $DISOWN_PID 2>/dev/null
```

## Expected Outcome

- `~/practice/jobs/wait_demo.sh` — uses `wait` to collect background job exit codes
- `~/practice/jobs/parallel.sh` — runs parallel jobs and detects failure with `wait`
- You can use `disown` to detach a running job from the shell's job table
