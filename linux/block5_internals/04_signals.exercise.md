# Exercise: Signals

## Setup

```bash
mkdir -p ~/practice
```

## Task 1: List All Signals

```bash
kill -l
```

Note signal numbers for: SIGTERM, SIGKILL, SIGHUP, SIGINT, SIGUSR1.

## Task 2: Send Signals to a Background Process

Start a background process and send it signals:

```bash
# Start a long-running background process
sleep 300 &
BG_PID=$!
echo "Background PID: $BG_PID"

# Verify it's running
ps -p $BG_PID

# Send SIGTERM
kill $BG_PID

# Wait and check exit status
wait $BG_PID 2>/dev/null
echo "Exit status after SIGTERM: $?"
# Should be 143 (128+15)
```

## Task 3: Demonstrate SIGKILL Cannot Be Caught

```bash
# Start another background process
sleep 300 &
BG_PID=$!

# Kill it with SIGKILL
kill -9 $BG_PID
wait $BG_PID 2>/dev/null
echo "Exit status after SIGKILL: $?"
# Should be 137 (128+9)
```

## Task 4: Write a Script with Signal Trapping

Create a shell script that uses `trap` to handle signals gracefully:

```bash
cat > ~/practice/signal_trap.sh << 'EOF'
#!/bin/bash

CLEANUP_DONE=0

cleanup() {
    if [ $CLEANUP_DONE -eq 0 ]; then
        CLEANUP_DONE=1
        echo "Signal received! Cleaning up..."
        rm -f /tmp/signal_test_$$
        echo "Cleanup complete. Exiting."
    fi
    exit 0
}

# Set up traps for common termination signals
trap cleanup SIGTERM SIGINT SIGHUP

# Create a temp file to demonstrate cleanup
touch /tmp/signal_test_$$
echo "Created temp file: /tmp/signal_test_$$"
echo "Script PID: $$"
echo "Waiting... Send SIGTERM with: kill $$"

# Loop until a signal arrives
COUNT=0
while true; do
    sleep 1
    COUNT=$((COUNT + 1))
    echo "Running for ${COUNT}s..."
    if [ $COUNT -ge 30 ]; then
        echo "Timeout reached, exiting normally."
        cleanup
    fi
done
EOF

chmod +x ~/practice/signal_trap.sh
```

Verify the script has the trap statement:
```bash
grep trap ~/practice/signal_trap.sh
```

## Task 5: Test the Trap Script

Run the trap script in the background, then send it a signal:

```bash
# Run in background
~/practice/signal_trap.sh &
TRAP_PID=$!
echo "Trap script running with PID: $TRAP_PID"

# Let it run for 2 seconds
sleep 2

# Send SIGTERM — the trap should catch it and clean up
kill -TERM $TRAP_PID
wait $TRAP_PID 2>/dev/null
echo "Trap script exited with status: $?"
```

## Task 6: Read Signal Masks from /proc

Check the signal disposition of a process:

```bash
cat /proc/$$/status | grep -E "^Sig(Pnd|Blk|Ign|Cgt)"
```

The values are hexadecimal bitmasks. Each bit position corresponds to a signal number. A value of `0000000000000000` means no signals in that category.

## Expected Outcome

- `~/practice/signal_trap.sh` exists and contains a `trap` statement
- You can send signals with `kill` using both names and numbers
- You understand that SIGKILL cannot be caught
