# Exercise: Huge Pages and THP

## Setup

```bash
mkdir -p ~/practice/hugepages
```

## Task 1: Inspect Current Huge Page State

```bash
echo "=== Huge Pages from /proc/meminfo ==="
grep -i huge /proc/meminfo

echo ""
echo "=== Explicit Huge Page Pool ==="
cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages 2>/dev/null && \
    echo "2MB huge pages allocated" || echo "hugepages-2048kB not available"

echo ""
echo "=== 1GB Huge Pages ==="
cat /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages 2>/dev/null || \
    echo "1GB huge pages not available or not configured"
```

## Task 2: Check THP Configuration

```bash
echo "=== Transparent Huge Pages ==="
echo "THP enabled setting:"
cat /sys/kernel/mm/transparent_hugepage/enabled

echo ""
echo "THP defrag setting:"
cat /sys/kernel/mm/transparent_hugepage/defrag

echo ""
echo "khugepaged scan sleep (ms):"
cat /sys/kernel/mm/transparent_hugepage/khugepaged/scan_sleep_millisecs
```

Note: the current setting is shown in `[brackets]`.

## Task 3: Measure THP in Use

```bash
echo "=== THP Currently in Use ==="
awk '/^AnonHugePages:/{print $2 " kB (" $2/1024 " MB)"}' /proc/meminfo

# Per-process THP (may require root)
echo ""
echo "Top processes by THP usage:"
awk '/^AnonHugePages:/ && $2 > 0 {print FILENAME, $2}' \
    /proc/[0-9]*/smaps 2>/dev/null \
    | sed 's|/proc/||;s|/smaps||' \
    | sort -k2 -rn \
    | head -10 \
    | while read pid_path kb; do
        comm=$(cat /proc/$pid_path/comm 2>/dev/null || echo "unknown")
        echo "  PID $pid_path ($comm): ${kb}kB"
      done
```

## Task 4: Adjust THP Settings (Non-Destructive)

```bash
# Save current setting
CURRENT_THP=$(cat /sys/kernel/mm/transparent_hugepage/enabled | grep -oP '\[\K[^\]]+')
echo "Current THP setting: $CURRENT_THP"

# Switch to madvise mode (safer for latency-sensitive workloads)
echo madvise | sudo tee /sys/kernel/mm/transparent_hugepage/enabled

echo "New THP setting:"
cat /sys/kernel/mm/transparent_hugepage/enabled

# Restore original setting
echo "$CURRENT_THP" | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo "Restored to: $(cat /sys/kernel/mm/transparent_hugepage/enabled | grep -oP '\[\K[^\]]+')"
```

## Task 5: Allocate Explicit Huge Pages (If Supported)

```bash
# Read current allocation
CURRENT=$(cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages 2>/dev/null || echo 0)
echo "Current huge pages: $CURRENT"

# Try to allocate 4 huge pages (8MB) — may fail in containers
echo 4 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages 2>/dev/null
NEW=$(cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages 2>/dev/null || echo 0)
echo "After allocation: $NEW"

if [ "$NEW" -ge 4 ]; then
    echo "Huge page allocation succeeded"
else
    echo "Huge page allocation not supported in this environment (normal for containers)"
fi

# Restore
echo "$CURRENT" | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages 2>/dev/null || true
```

## Task 6: Write a Huge Page Summary Script

```bash
cat > ~/practice/hugepages/hugepage_summary.sh << 'EOF'
#!/bin/bash
echo "=== Huge Page Summary ==="

# THP status
THP=$(cat /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null | grep -oP '\[\K[^\]]+')
DEFRAG=$(cat /sys/kernel/mm/transparent_hugepage/defrag 2>/dev/null | grep -oP '\[\K[^\]]+')
echo "THP: $THP (defrag: $defrag)"
echo "Defrag: ${DEFRAG:-unknown}"

# THP in use
THP_KB=$(awk '/^AnonHugePages:/{print $2}' /proc/meminfo)
echo "THP in use: ${THP_KB}kB ($(( THP_KB / 1024 )) MB)"

# Explicit huge pages
HP_TOTAL=$(awk '/^HugePages_Total:/{print $2}' /proc/meminfo)
HP_FREE=$(awk '/^HugePages_Free:/{print $2}' /proc/meminfo)
HP_SIZE=$(awk '/^Hugepagesize:/{print $2}' /proc/meminfo)
echo ""
echo "Explicit huge pages: $HP_TOTAL total, $HP_FREE free (${HP_SIZE}kB each)"

# Total huge page memory reserved
RESERVED=$(( HP_TOTAL * HP_SIZE ))
echo "Reserved: $(( RESERVED / 1024 )) MB"
EOF
chmod +x ~/practice/hugepages/hugepage_summary.sh
bash ~/practice/hugepages/hugepage_summary.sh
```

## Expected Outcome

- `/proc/meminfo` shows HugePages_* and AnonHugePages fields
- `/sys/kernel/mm/transparent_hugepage/enabled` shows current THP mode in `[brackets]`
- THP `defrag` setting is readable
- THP mode can be switched between `always`, `madvise`, `never`
- `~/practice/hugepages/hugepage_summary.sh` reports THP and explicit huge page state
