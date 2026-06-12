# Exercise: The OOM Killer and Memory Overcommit

## Setup

```bash
mkdir -p ~/practice/oom
```

## Task 1: Check Overcommit Settings

```bash
echo "=== Memory Overcommit Settings ==="
echo "overcommit_memory: $(cat /proc/sys/vm/overcommit_memory)"
echo "  0 = heuristic, 1 = always, 2 = strict"
echo ""
echo "overcommit_ratio: $(cat /proc/sys/vm/overcommit_ratio)%"
echo ""
echo "Commit limit vs actual usage:"
awk '/CommitLimit/{printf "CommitLimit:   %d MB\n", $2/1024}
     /Committed_AS/{printf "Committed_AS:  %d MB\n", $2/1024}' /proc/meminfo
```

## Task 2: Read OOM Scores

```bash
echo "=== OOM Scores ==="
echo "This shell: $(cat /proc/$$/oom_score)"
echo "Adjustment: $(cat /proc/$$/oom_score_adj)"
echo ""

# PID 1 (init/systemd)
echo "PID 1 (systemd/init):"
echo "  oom_score:     $(cat /proc/1/oom_score 2>/dev/null || echo N/A)"
echo "  oom_score_adj: $(cat /proc/1/oom_score_adj 2>/dev/null || echo N/A)"
```

## Task 3: View Top OOM Score Processes

```bash
echo "=== Processes by OOM Score (highest first) ==="
for pid in /proc/[0-9]*/oom_score; do
    score=$(cat "$pid" 2>/dev/null)
    [ -z "$score" ] || [ "$score" = "0" ] && continue
    proc=$(dirname "$pid")
    comm=$(cat "$proc/comm" 2>/dev/null || echo "?")
    adj=$(cat "$proc/oom_score_adj" 2>/dev/null || echo "?")
    rss=$(awk '/^VmRSS/{print $2}' "$proc/status" 2>/dev/null || echo "0")
    echo "$score $comm (PID=$(basename $proc), adj=$adj, RSS=${rss}kB)"
done | sort -rn | head -10
```

## Task 4: Adjust oom_score_adj for a Process

```bash
# Spawn a background process
sleep 300 &
SLEEP_PID=$!

echo "Before: oom_score=$(cat /proc/$SLEEP_PID/oom_score), adj=$(cat /proc/$SLEEP_PID/oom_score_adj)"

# Mark it as expendable (kill first)
echo 500 | sudo tee /proc/$SLEEP_PID/oom_score_adj > /dev/null
echo "After adj=500: oom_score=$(cat /proc/$SLEEP_PID/oom_score)"

# Protect it (never kill)
echo -500 | sudo tee /proc/$SLEEP_PID/oom_score_adj > /dev/null
echo "After adj=-500: oom_score=$(cat /proc/$SLEEP_PID/oom_score)"

# Cleanup
kill $SLEEP_PID 2>/dev/null
```

## Task 5: Check for Historical OOM Events

```bash
echo "=== Historical OOM Kill Events ==="
journalctl -k --no-pager 2>/dev/null | grep -i "out of memory\|oom.kill" | tail -10 \
    || dmesg | grep -i "out of memory\|oom.kill" | tail -10 \
    || echo "No OOM events found in kernel log (system is healthy)"
```

## Task 6: Calculate Memory Pressure

```bash
cat > ~/practice/oom/mem_pressure.sh << 'EOF'
#!/bin/bash
echo "=== Memory Pressure Check ==="

# Overcommit
MODE=$(cat /proc/sys/vm/overcommit_memory)
echo "Overcommit mode: $MODE"

# Commit ratio
awk '
/CommitLimit/{limit=$2}
/Committed_AS/{committed=$2}
/MemTotal/{total=$2}
/MemFree/{free=$2}
/MemAvailable/{avail=$2}
/SwapTotal/{swap_total=$2}
/SwapFree/{swap_free=$2}
END {
    printf "RAM: %d MB total, %d MB free, %d MB available\n",
        total/1024, free/1024, avail/1024
    printf "Swap: %d MB total, %d MB free\n",
        swap_total/1024, swap_free/1024
    printf "Commit: %d/%d MB (%.1f%%)\n",
        committed/1024, limit/1024, committed*100/limit
    if (committed/limit > 0.9) print "WARNING: commit ratio above 90%"
}' /proc/meminfo

echo ""
echo "Swappiness: $(sysctl -n vm.swappiness)"
echo "Top OOM scores:"
for pid in /proc/[0-9]*/oom_score; do
    score=$(cat "$pid" 2>/dev/null)
    [ "${score:-0}" -gt 100 ] || continue
    comm=$(cat "$(dirname $pid)/comm" 2>/dev/null)
    echo "  $score $comm"
done | sort -rn | head -5
EOF
chmod +x ~/practice/oom/mem_pressure.sh
bash ~/practice/oom/mem_pressure.sh
```

## Expected Outcome

- `/proc/sys/vm/overcommit_memory` and `overcommit_ratio` are readable
- `/proc/meminfo` CommitLimit and Committed_AS show the commit utilization
- OOM scores for all processes are readable from `/proc/<pid>/oom_score`
- `oom_score_adj` can be changed for processes you own (or with sudo)
- `~/practice/oom/mem_pressure.sh` summarizes memory commit state and top OOM scores
