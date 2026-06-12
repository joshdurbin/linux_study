# Memory Analysis — Exercises

Complete these tasks. Record findings in `~/practice/memory_analysis.txt`.

## Setup

```bash
mkdir -p ~/practice
```

## Task 1 — Interpret free -h

```bash
echo "=== free -h output ===" >> ~/practice/memory_analysis.txt
free -h >> ~/practice/memory_analysis.txt
```

After running, add a comment answering:
- What is the `available` memory?
- Is `buff/cache` larger than `used`? (Normal on most servers.)
- Is any swap in use?

```bash
echo "# My observation: available=<X>, swap in use=<yes/no>" >> ~/practice/memory_analysis.txt
```

## Task 2 — Read /proc/meminfo fields

Extract and record specific fields:

```bash
echo "=== /proc/meminfo key fields ===" >> ~/practice/memory_analysis.txt
grep -E '^(MemTotal|MemFree|MemAvailable|Dirty|Writeback|AnonPages|Slab|SwapTotal|SwapFree):' \
    /proc/meminfo >> ~/practice/memory_analysis.txt
```

Note the `Dirty` value — if it is very high relative to RAM, the system has unflushed writes.

## Task 3 — Watch vmstat memory columns

```bash
echo "=== vmstat 1 5 ===" >> ~/practice/memory_analysis.txt
vmstat 1 5 >> ~/practice/memory_analysis.txt
```

Check columns `si` and `so`. Are they non-zero? (Swapping is memory saturation.)

## Task 4 — Record MemAvailable

```bash
echo "=== MemAvailable snapshot ===" >> ~/practice/memory_analysis.txt
grep MemAvailable /proc/meminfo >> ~/practice/memory_analysis.txt
```

## Task 5 — Check for OOM events

```bash
echo "=== OOM kernel messages ===" >> ~/practice/memory_analysis.txt
dmesg | grep -i oom >> ~/practice/memory_analysis.txt || echo "No OOM events found" >> ~/practice/memory_analysis.txt
```

## Verification

```bash
cat ~/practice/memory_analysis.txt
```

The file should contain output from all tools and your written observations.
