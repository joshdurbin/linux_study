# perf Basics — Exercises

> **Note:** `perf` requires either a privileged container (`--privileged`) or `perf_event_paranoid <= 1`.
> If `perf` is unavailable, complete Tasks 1–3 using the fallback methods, then document what `perf` *would* show in Tasks 4–5.

Complete these tasks. Record findings in `~/practice/perf_notes.txt`.

## Setup

```bash
mkdir -p ~/practice
```

## Task 1 — Check perf availability

```bash
echo "=== perf availability check ===" >> ~/practice/perf_notes.txt
cat /proc/sys/kernel/perf_event_paranoid >> ~/practice/perf_notes.txt
which perf >> ~/practice/perf_notes.txt 2>&1 || echo "perf not found" >> ~/practice/perf_notes.txt
```

## Task 2 — perf stat (if available) or fallback

**If perf is available:**
```bash
echo "=== perf stat ls ===" >> ~/practice/perf_notes.txt
perf stat ls /tmp 2>> ~/practice/perf_notes.txt
```

**If perf is NOT available (fallback — /proc/stat cpu times):**
```bash
echo "=== /proc/stat CPU times (perf fallback) ===" >> ~/practice/perf_notes.txt
awk '/^cpu / {print "user="$2, "nice="$3, "sys="$4, "idle="$5, "iowait="$6}' /proc/stat >> ~/practice/perf_notes.txt
```

## Task 3 — Process scheduling stats

```bash
echo "=== schedstat for current shell ===" >> ~/practice/perf_notes.txt
cat /proc/$$/schedstat >> ~/practice/perf_notes.txt
echo "# Fields: runtime_ns wait_time_ns timeslices" >> ~/practice/perf_notes.txt
```

## Task 4 — perf list (if available)

```bash
echo "=== perf list (hardware events) ===" >> ~/practice/perf_notes.txt
if command -v perf &>/dev/null; then
    perf list hardware 2>> ~/practice/perf_notes.txt | head -20 >> ~/practice/perf_notes.txt
else
    echo "perf unavailable — available tracing events via /sys/kernel/debug/tracing:" >> ~/practice/perf_notes.txt
    ls /sys/kernel/debug/tracing/events/ 2>> ~/practice/perf_notes.txt || echo "debugfs not mounted" >> ~/practice/perf_notes.txt
fi
```

## Task 5 — Document perf record workflow

Add a note explaining what you would run for a real workload:

```bash
cat >> ~/practice/perf_notes.txt << 'EOF'
=== perf record workflow (documented) ===
# Step 1: Record 10 seconds of system-wide CPU profiling:
#   sudo perf record -g -F 99 -a sleep 10
#
# Step 2: View interactive call tree:
#   sudo perf report
#
# Step 3: Generate flamegraph input:
#   sudo perf script > out.perf
#
# Key metrics to check in perf stat output:
#   - IPC (instructions per cycle): <0.5 = stalled, >2 = efficient
#   - cache-miss rate: high % = memory-bound
#   - branch-miss rate: high % = branch-prediction-limited
EOF
```

## Verification

```bash
cat ~/practice/perf_notes.txt
```
