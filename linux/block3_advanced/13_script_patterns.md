# Shell Script Operational Patterns

Scripts that run in production need to handle the real world: concurrent execution, partial failures, cleanup on interruption, and safe file operations. These patterns prevent a class of bugs that only manifest under load or at 3am during an incident.

## Lock Files — Preventing Concurrent Execution

A lock file ensures only one instance of a script runs at a time. The critical requirement is **atomicity** — the check-and-create must be a single operation.

```bash
#!/bin/bash
LOCKFILE=/var/run/myscript.lock

# Atomic lock using ln (hard links are atomic on POSIX filesystems)
# This is safer than using a simple file create, which has a race window.
TMPFILE=$(mktemp)
echo $$ > "$TMPFILE"

if ln "$TMPFILE" "$LOCKFILE" 2>/dev/null; then
    rm -f "$TMPFILE"
    echo "Lock acquired (PID $$)"
    trap 'rm -f "$LOCKFILE"; exit' EXIT INT TERM
else
    EXISTING_PID=$(cat "$LOCKFILE" 2>/dev/null)
    if kill -0 "$EXISTING_PID" 2>/dev/null; then
        echo "Already running as PID $EXISTING_PID" >&2
        rm -f "$TMPFILE"
        exit 1
    else
        echo "Stale lock (PID $EXISTING_PID no longer running) — stealing"
        rm -f "$LOCKFILE"
        mv "$TMPFILE" "$LOCKFILE"
    fi
fi
```

### flock — The Simpler Alternative

```bash
#!/bin/bash
LOCKFILE=/var/run/myscript.lock

# flock(1) handles the atomic open+lock in one call
exec 200>"$LOCKFILE"
if ! flock -n 200; then
    echo "Already running" >&2
    exit 1
fi
echo $$ >&200    # write PID into the lock file

# The lock is held as long as FD 200 is open (i.e., while the script runs)
# Automatically released on script exit, even on crash

echo "Lock acquired, doing work..."
# ... work ...
```

```bash
# One-liner: run a command only if the lock is available
flock -n /var/run/mylock.lock ./myscript.sh

# With timeout: wait up to 30 seconds for the lock
flock -w 30 /var/run/mylock.lock ./myscript.sh

# Inside a subshell
(
    flock -n 9 || { echo "Already running"; exit 1; }
    echo "Critical section"
) 9>/var/run/mylock.lock
```

## PID Files — Daemon Tracking

PID files let other scripts and monitoring tools find a running daemon's PID without process name searches.

```bash
PIDFILE=/var/run/myscript.pid

# Write PID at startup
echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"; exit' EXIT INT TERM

# Check if daemon is running
is_running() {
    local pidfile="$1"
    local pid
    pid=$(cat "$pidfile" 2>/dev/null) || return 1
    kill -0 "$pid" 2>/dev/null       # kill -0 checks if process exists, sends no signal
}

# Usage:
if is_running "$PIDFILE"; then
    echo "Daemon is running (PID $(cat $PIDFILE))"
else
    echo "Daemon is not running"
fi
```

## Atomic File Writes

Writing to a file directly risks leaving a partially-written file if the process is interrupted or crashes mid-write. Use a temp file + atomic rename:

```bash
# UNSAFE: writes directly — another process reading during write sees partial data
cat > /etc/myapp/config.json << 'EOF'
{"setting": "value"}
EOF

# SAFE: write to temp, then atomic rename
TMPFILE=$(mktemp /etc/myapp/config.json.XXXXXX)
cat > "$TMPFILE" << 'EOF'
{"setting": "value"}
EOF
# rename(2) is atomic on the same filesystem — readers never see a partial state
mv "$TMPFILE" /etc/myapp/config.json
```

```bash
# Template: safe write function
safe_write() {
    local dest="$1"
    local tmpfile
    tmpfile=$(mktemp "${dest}.XXXXXX")
    # Write to tmp, ensuring cleanup on failure
    if cat > "$tmpfile"; then
        mv "$tmpfile" "$dest"
    else
        rm -f "$tmpfile"
        return 1
    fi
}

echo '{"key": "value"}' | safe_write /etc/myapp/config.json
```

## Idempotent Scripts

An idempotent script produces the same result whether run once or 100 times. Essential for deployment scripts and cron jobs.

```bash
# Non-idempotent: fails on second run
mkdir /opt/myapp
cp myapp /opt/myapp/myapp

# Idempotent: safe to run repeatedly
mkdir -p /opt/myapp                           # -p: no error if exists
cp -f myapp /opt/myapp/myapp                  # -f: overwrite existing

# Check before acting
if ! grep -q "myapp_user" /etc/passwd; then
    useradd --system --no-create-home myapp_user
fi

# Install a config only if it doesn't exist (don't overwrite customizations)
[ -f /etc/myapp/config.toml ] || cp config.toml.default /etc/myapp/config.toml

# Append to a file only if the line isn't already there
grep -qF "export MYAPP_HOME=/opt/myapp" /etc/profile || \
    echo "export MYAPP_HOME=/opt/myapp" >> /etc/profile
```

## trap — Cleanup on Exit

```bash
#!/bin/bash
set -euo pipefail

TMPDIR_WORK=$(mktemp -d)
LOCKFILE=/var/run/myscript.lock

cleanup() {
    local exit_code=$?
    echo "Cleaning up (exit code: $exit_code)" >&2
    rm -rf "$TMPDIR_WORK"
    rm -f "$LOCKFILE"
    exit $exit_code
}

# EXIT fires on any exit: normal, error, or signal
trap cleanup EXIT

# SIGINT (Ctrl-C) and SIGTERM will both trigger cleanup via EXIT
trap 'echo "Interrupted" >&2' INT TERM

# Now if the script fails or is interrupted, cleanup always runs
touch "$LOCKFILE"
do_work "$TMPDIR_WORK"
```

## Retry with Backoff

```bash
# Retry a command up to N times with exponential backoff
retry() {
    local max_attempts="$1"; shift
    local delay=1
    local attempt=1
    while true; do
        "$@" && return 0
        if [ "$attempt" -ge "$max_attempts" ]; then
            echo "Failed after $attempt attempts" >&2
            return 1
        fi
        echo "Attempt $attempt failed, retrying in ${delay}s..." >&2
        sleep "$delay"
        delay=$((delay * 2))
        attempt=$((attempt + 1))
    done
}

# Usage:
retry 5 curl -sf https://api.example.com/health
retry 3 pg_dump mydb > /backup/mydb.sql
```

## Parallel Jobs with Error Tracking

```bash
#!/bin/bash
# Run N jobs in parallel, collect all their exit codes

PIDS=()
STATUS=()

# Launch jobs
for item in host1 host2 host3 host4; do
    ssh "$item" 'apt-get update -q' &
    PIDS+=($!)
done

# Collect results
FAILED=0
for i in "${!PIDS[@]}"; do
    wait "${PIDS[$i]}"
    STATUS[$i]=$?
    if [ "${STATUS[$i]}" -ne 0 ]; then
        echo "Job $i (PID ${PIDS[$i]}) failed with exit code ${STATUS[$i]}" >&2
        FAILED=1
    fi
done

[ "$FAILED" -eq 0 ] && echo "All jobs succeeded" || { echo "Some jobs failed" >&2; exit 1; }
```

## Script Template

```bash
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ---- Config ----
SCRIPT_NAME=$(basename "$0" .sh)
LOCKFILE="/var/run/${SCRIPT_NAME}.lock"
LOG_PREFIX="[$SCRIPT_NAME]"

# ---- Logging ----
log() { echo "${LOG_PREFIX} $*" >&2; }
die() { log "ERROR: $*"; exit 1; }

# ---- Cleanup ----
cleanup() { rm -f "$LOCKFILE"; }
trap cleanup EXIT

# ---- Lock ----
exec 200>"$LOCKFILE"
flock -n 200 || die "Already running"
echo $$ >&200

# ---- Main ----
log "Starting"
# ... your code here ...
log "Done"
```

## Further Reading

- [flock(2) — man7.org](https://man7.org/linux/man-pages/man2/flock.2.html) — authoritative kernel reference for `flock(2)` semantics: per-open-file-description locking, NFS caveats, behavior across fork/exec, and why `LOCK_EX` is not process-exclusive.
- [mkstemp(3) — man7.org](https://man7.org/linux/man-pages/man3/mkstemp.3.html) — documents `mkstemp(3)` and the `mktemp(1)` wrapper, including why the `O_CREAT|O_EXCL` combination is used internally to create temp files without a TOCTOU race window.
- [BashFAQ/045 — Race conditions and shell scripts](https://mywiki.wooledge.org/BashFAQ/045) — Greg Wooledge's analysis of TOCTOU races in Bash scripts, explaining exactly which idioms create race windows and how atomic operations (ln, mv, flock) close them.
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) — Google's production shell standards covering the script template pattern, lock file idioms, logging conventions, and when scripts become too large and should be rewritten in Python.
