# Exercise: File Locking

## Setup

```bash
mkdir -p ~/practice/file_locking
```

## Task 1: View Current Locks in the System

```bash
echo "=== /proc/locks ==="
cat /proc/locks | head -20

echo ""
echo "Lock count: $(wc -l < /proc/locks)"
```

## Task 2: Acquire and Observe an Exclusive Lock

```bash
LOCKFILE=~/practice/file_locking/test.lock

# Acquire a lock in background, hold it for 10 seconds
(
    flock -n 9 || { echo "Could not acquire lock"; exit 1; }
    echo "Lock acquired by PID $$ (sleep 10s)"
    sleep 10
) 9>"$LOCKFILE" &
HOLDER_PID=$!

sleep 0.5

# Try to acquire the same lock non-blocking
if flock -n "$LOCKFILE" true; then
    echo "Lock was available (unexpected)"
else
    echo "Lock is held — flock -n returned non-zero (expected)"
fi

# Wait up to 2 seconds
if flock -w 2 "$LOCKFILE" echo "Got lock after wait"; then
    echo "(Unlikely — would require timeout)"
else
    echo "Timeout waiting for lock (expected)"
fi

kill $HOLDER_PID 2>/dev/null
wait $HOLDER_PID 2>/dev/null
echo "Lock holder exited"

# Now the lock should be available
flock -n "$LOCKFILE" echo "Lock now available (correct)"
```

## Task 3: Shared vs Exclusive Locks

```bash
LOCKFILE=~/practice/file_locking/shared.lock

# Acquire a shared lock in background
(
    flock -s 9
    echo "Reader 1 acquired shared lock"
    sleep 5
) 9>"$LOCKFILE" &
R1_PID=$!

sleep 0.3

# Another shared lock should succeed immediately
(
    flock -sn 9 && echo "Reader 2 got shared lock (expected)" || echo "Reader 2 blocked (unexpected)"
) 9>"$LOCKFILE"

# An exclusive lock should block (readers are holding shared locks)
(
    flock -wn 9 echo "Writer got exclusive lock" || echo "Writer blocked by shared locks (expected)"
) 9>"$LOCKFILE"

kill $R1_PID 2>/dev/null
wait $R1_PID 2>/dev/null
```

## Task 4: Read /proc/locks with a Held Lock

```bash
LOCKFILE=~/practice/file_locking/proc_test.lock

# Acquire lock and find it in /proc/locks
exec 9>"$LOCKFILE"
flock 9

INODE=$(stat -c%i "$LOCKFILE" 2>/dev/null)
echo "Lock file inode: $INODE"

echo "/proc/locks entries for this inode:"
grep "$INODE" /proc/locks 2>/dev/null || echo "Not visible (may need different inode format)"

# Alternative: check by PID
echo ""
echo "/proc/locks for current PID ($$):"
grep " $$ " /proc/locks 2>/dev/null | head -5 || echo "PID not shown (normal for flock)"

# Release
flock -u 9
exec 9>&-
```

## Task 5: fuser — Find Who Holds a Lock

```bash
LOCKFILE=~/practice/file_locking/fuser_test.lock

# Hold a lock
exec 9>"$LOCKFILE"
flock 9

echo "PID $$ holds lock on $LOCKFILE"

# Find who is using the file
echo "fuser output:"
fuser "$LOCKFILE" 2>/dev/null || echo "fuser not available"

echo ""
echo "lsof output:"
lsof "$LOCKFILE" 2>/dev/null | head -5 || echo "lsof not available"

# Release
flock -u 9
exec 9>&-
```

## Task 6: Write a Lock-Aware Script Template

```bash
cat > ~/practice/file_locking/safe_runner.sh << 'EOF'
#!/bin/bash
# Template: run a critical section with exclusive file lock
LOCKFILE="${TMPDIR:-/tmp}/safe_runner_$$.lock"
TIMEOUT=30

run_with_lock() {
    local lockfile="$1"
    local timeout="$2"
    shift 2

    exec 9>"$lockfile"
    if ! flock -w "$timeout" 9; then
        echo "ERROR: Could not acquire lock on $lockfile within ${timeout}s" >&2
        exec 9>&-
        return 1
    fi
    echo $$ >&9

    echo "Lock acquired by PID $$"
    "$@"
    local exit_code=$?

    flock -u 9
    exec 9>&-
    return $exit_code
}

critical_section() {
    echo "In critical section (PID $$, $(date))"
    sleep 2
    echo "Critical section complete"
}

run_with_lock "$LOCKFILE" "$TIMEOUT" critical_section
EXIT_CODE=$?
rm -f "$LOCKFILE"
exit $EXIT_CODE
EOF
chmod +x ~/practice/file_locking/safe_runner.sh

# Test it
bash ~/practice/file_locking/safe_runner.sh
```

## Expected Outcome

- `/proc/locks` is readable and shows current system locks
- `flock -n` returns non-zero immediately if a lock is held
- `flock -s` allows multiple concurrent shared lock holders
- Shared locks block exclusive locks
- `fuser` and `lsof` can identify which process holds a lock file open
- `safe_runner.sh` uses `flock -w` with a timeout and releases on exit
