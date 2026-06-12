# Exercise: Shell Script Operational Patterns

## Setup

```bash
mkdir -p ~/practice/script_patterns
```

## Task 1: Lock File with flock

```bash
cat > ~/practice/script_patterns/locked_job.sh << 'EOF'
#!/bin/bash
LOCKFILE=/tmp/locked_job.lock

exec 200>"$LOCKFILE"
if ! flock -n 200; then
    echo "Already running (lock held)" >&2
    exit 1
fi
echo $$ >&200

echo "Lock acquired by PID $$"
echo "Doing work for 5 seconds..."
sleep 5
echo "Done"
EOF
chmod +x ~/practice/script_patterns/locked_job.sh

# Test: run in background, then try to run again
~/practice/script_patterns/locked_job.sh &
JOB_PID=$!
sleep 1

echo "Trying to run a second instance:"
~/practice/script_patterns/locked_job.sh && echo "Second ran" || echo "Second blocked (expected)"

wait $JOB_PID
```

## Task 2: PID File Pattern

```bash
cat > ~/practice/script_patterns/daemon_sim.sh << 'EOF'
#!/bin/bash
PIDFILE=/tmp/daemon_sim.pid

# Check if already running
if [ -f "$PIDFILE" ]; then
    EXISTING=$(cat "$PIDFILE")
    if kill -0 "$EXISTING" 2>/dev/null; then
        echo "Already running as PID $EXISTING" >&2
        exit 1
    else
        echo "Stale PID file (PID $EXISTING gone), removing"
        rm -f "$PIDFILE"
    fi
fi

echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"; echo "Cleaned up PID file"' EXIT

echo "Daemon started (PID $$, written to $PIDFILE)"
sleep 10
echo "Daemon exiting normally"
EOF
chmod +x ~/practice/script_patterns/daemon_sim.sh

# Test PID file creation
~/practice/script_patterns/daemon_sim.sh &
DAEMON_PID=$!
sleep 1

echo "PID file contents: $(cat /tmp/daemon_sim.pid)"
echo "Process running: $(kill -0 $DAEMON_PID 2>/dev/null && echo yes || echo no)"

# Try to start a second instance
~/practice/script_patterns/daemon_sim.sh && echo "Second started" || echo "Second blocked (expected)"

kill $DAEMON_PID 2>/dev/null
wait $DAEMON_PID 2>/dev/null
echo "After exit, PID file: $(ls /tmp/daemon_sim.pid 2>/dev/null || echo 'removed (correct)')"
```

## Task 3: Atomic File Write

```bash
# Safe write function
safe_write() {
    local dest="$1"
    local tmpfile
    tmpfile=$(mktemp "${dest}.XXXXXX")
    if cat > "$tmpfile"; then
        mv "$tmpfile" "$dest"
        echo "Atomically wrote to $dest"
    else
        rm -f "$tmpfile"
        echo "Write failed" >&2
        return 1
    fi
}

TARGET=~/practice/script_patterns/config.json

# Write atomically
echo '{"version": 1, "setting": "value"}' | safe_write "$TARGET"
cat "$TARGET"

# Update atomically
echo '{"version": 2, "setting": "updated"}' | safe_write "$TARGET"
cat "$TARGET"
```

## Task 4: Idempotent Operations

```bash
cat > ~/practice/script_patterns/setup_idempotent.sh << 'EOF'
#!/bin/bash
INSTALL_DIR=~/practice/script_patterns/app
CONFIG=~/practice/script_patterns/app.conf

echo "=== Running idempotent setup ==="

# Idempotent directory creation
mkdir -p "$INSTALL_DIR"
echo "Directory exists: $INSTALL_DIR"

# Idempotent file creation (only if missing)
if [ ! -f "$CONFIG" ]; then
    echo "# Default config" > "$CONFIG"
    echo "timeout=30" >> "$CONFIG"
    echo "Created $CONFIG"
else
    echo "Config already exists, skipping"
fi

# Idempotent line append
if ! grep -qF "# managed by setup" "$CONFIG"; then
    echo "# managed by setup" >> "$CONFIG"
    echo "Added marker line"
else
    echo "Marker line already present"
fi

echo "=== Setup complete ==="
cat "$CONFIG"
EOF
chmod +x ~/practice/script_patterns/setup_idempotent.sh

# Run twice — second run should produce same result
echo "=== First run ==="
bash ~/practice/script_patterns/setup_idempotent.sh
echo ""
echo "=== Second run (idempotent) ==="
bash ~/practice/script_patterns/setup_idempotent.sh
```

## Task 5: Retry with Backoff

```bash
cat > ~/practice/script_patterns/retry.sh << 'EOF'
#!/bin/bash
retry() {
    local max="$1"; shift
    local delay=1
    local attempt=1
    while true; do
        "$@" && return 0
        if [ "$attempt" -ge "$max" ]; then
            echo "ERROR: Failed after $attempt attempts" >&2
            return 1
        fi
        echo "Attempt $attempt failed, retrying in ${delay}s..." >&2
        sleep "$delay"
        delay=$((delay * 2))
        attempt=$((attempt + 1))
    done
}

# Test with a command that fails a few times then succeeds
ATTEMPT_FILE=/tmp/retry_test_attempts_$$
echo 0 > "$ATTEMPT_FILE"

flaky_command() {
    ATTEMPTS=$(cat "$ATTEMPT_FILE")
    ATTEMPTS=$((ATTEMPTS + 1))
    echo "$ATTEMPTS" > "$ATTEMPT_FILE"
    echo "Attempt $ATTEMPTS"
    [ "$ATTEMPTS" -ge 3 ] && return 0 || return 1
}

echo "Testing retry (will fail twice then succeed):"
retry 5 flaky_command
echo "Final result: $?"
rm -f "$ATTEMPT_FILE"
EOF
chmod +x ~/practice/script_patterns/retry.sh
bash ~/practice/script_patterns/retry.sh
```

## Task 6: Cleanup with trap

```bash
cat > ~/practice/script_patterns/cleanup_demo.sh << 'EOF'
#!/bin/bash
set -euo pipefail

TMPDIR_WORK=$(mktemp -d)
echo "Created temp dir: $TMPDIR_WORK"

cleanup() {
    local code=$?
    echo "Cleanup running (exit code: $code)"
    rm -rf "$TMPDIR_WORK"
    echo "Temp dir removed: $(ls -d $TMPDIR_WORK 2>/dev/null || echo 'gone')"
}
trap cleanup EXIT

# Do some work
touch "$TMPDIR_WORK/workfile.txt"
echo "Working..."

# Simulate an error (this triggers cleanup via EXIT)
ls /nonexistent_path 2>/dev/null || { echo "Command failed — cleanup will run"; exit 1; }
EOF
chmod +x ~/practice/script_patterns/cleanup_demo.sh
bash ~/practice/script_patterns/cleanup_demo.sh || true
```

## Expected Outcome

- `locked_job.sh` — second invocation blocked by flock; first runs to completion
- `daemon_sim.sh` — PID file created on start, removed on exit; second invocation blocked
- `safe_write` writes atomically via temp + mv; no partial-write window
- `setup_idempotent.sh` produces identical results on first and second run
- `retry.sh` retries with increasing delays, succeeds after N attempts
- `cleanup_demo.sh` — trap removes temp dir even on failure
