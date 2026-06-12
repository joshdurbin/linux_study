# Exercise: ulimits and Resource Limits

## Setup

```bash
mkdir -p ~/practice/ulimits
```

## Task 1: View All Current Limits

```bash
echo "=== All limits for current shell ==="
ulimit -a

echo ""
echo "Soft vs Hard for open files:"
echo "  soft: $(ulimit -Sn)"
echo "  hard: $(ulimit -Hn)"
```

## Task 2: Read Limits from /proc

```bash
# Current process limits
cat /proc/$$/limits

# Specific field
awk '/open files/{print "FD limit: soft=" $4 " hard=" $5}' /proc/$$/limits
```

## Task 3: System-Wide FD State

```bash
echo "=== System-wide file descriptor usage ==="
cat /proc/sys/fs/file-nr
echo "Format: [in use]  [unused-reserved]  [max allowed]"

echo ""
echo "Kernel-wide FD ceiling:"
sysctl fs.file-max
```

## Task 4: Find the Process Using the Most FDs

```bash
echo "=== Top FD consumers ==="
for pid_fd in /proc/[0-9]*/fd; do
    count=$(ls "$pid_fd" 2>/dev/null | wc -l)
    echo "$count $pid_fd"
done 2>/dev/null | sort -rn | head -5 | while read count fddir; do
    pid=$(echo "$fddir" | cut -d/ -f3)
    comm=$(cat /proc/$pid/comm 2>/dev/null || echo "?")
    soft=$(awk '/open files/{print $4}' /proc/$pid/limits 2>/dev/null || echo "?")
    echo "  PID $pid ($comm): $count open / $soft limit"
done
```

## Task 5: Raise the Soft Limit in This Shell

```bash
CURRENT_SOFT=$(ulimit -Sn)
CURRENT_HARD=$(ulimit -Hn)
echo "Before: soft=$CURRENT_SOFT hard=$CURRENT_HARD"

# Raise soft to hard limit
ulimit -n $CURRENT_HARD

echo "After: soft=$(ulimit -Sn) hard=$(ulimit -Hn)"
```

## Task 6: Create a limits.d Configuration File

```bash
cat > ~/practice/ulimits/myapp.conf << 'EOF'
# Resource limits for myapp service user
# domain     type   item    value
myapp        soft   nofile  65536
myapp        hard   nofile  131072
myapp        soft   nproc   4096
myapp        hard   nproc   8192
*            soft   core    0
EOF
cat ~/practice/ulimits/myapp.conf
echo ""
echo "To install: sudo cp ~/practice/ulimits/myapp.conf /etc/security/limits.d/"
```

## Task 7: Use prlimit to Inspect a Running Process

```bash
# prlimit on the current shell
prlimit --pid $$

# Specific resource
prlimit --pid $$ --nofile
```

## Task 8: Write a FD Limit Check Script

```bash
cat > ~/practice/ulimits/check_fd_limits.sh << 'EOF'
#!/bin/bash
# Check FD usage vs limit for all processes, warn if above 80%
WARN_PCT=80

echo "=== File Descriptor Limit Check ==="
for pid_fd in /proc/[0-9]*/fd; do
    pid=$(echo "$pid_fd" | cut -d/ -f3)
    count=$(ls "$pid_fd" 2>/dev/null | wc -l)
    soft=$(awk '/open files/{print $4}' /proc/$pid/limits 2>/dev/null)
    [ -z "$soft" ] || [ "$soft" = "unlimited" ] && continue
    pct=$((count * 100 / soft))
    if [ "$pct" -ge "$WARN_PCT" ]; then
        comm=$(cat /proc/$pid/comm 2>/dev/null || echo "?")
        echo "WARNING: PID $pid ($comm) ${count}/${soft} FDs (${pct}%)"
    fi
done

# System-wide
TOTAL=$(awk '{print $1}' /proc/sys/fs/file-nr)
MAX=$(awk '{print $3}' /proc/sys/fs/file-nr)
SYS_PCT=$((TOTAL * 100 / MAX))
echo ""
echo "System-wide: ${TOTAL}/${MAX} FDs used (${SYS_PCT}%)"
[ "$SYS_PCT" -ge "$WARN_PCT" ] && echo "WARNING: system FD usage above ${WARN_PCT}%"
EOF
chmod +x ~/practice/ulimits/check_fd_limits.sh
bash ~/practice/ulimits/check_fd_limits.sh
```

## Expected Outcome

- `ulimit -a` shows all soft limits; `-Hn` shows hard limits
- `/proc/$$/limits` shows per-process limits in tabular form
- `/proc/sys/fs/file-nr` shows system-wide FD usage
- `prlimit` shows limits for any PID
- `~/practice/ulimits/myapp.conf` — PAM limits.d file with correct format
- `~/practice/ulimits/check_fd_limits.sh` — scans processes for FD limit warnings
