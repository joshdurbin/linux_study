# bpftrace Maps — Exercises

> **Container note:** bpftrace requires a privileged container. Document programs and their expected output if unavailable.

Complete these tasks. Record findings in `~/practice/bpftrace_maps.txt`.

## Setup

```bash
mkdir -p ~/practice
```

## Task 1 — Syscall count by process (run or document)

```bash
echo "=== Map example 1: syscall counts by process ===" >> ~/practice/bpftrace_maps.txt

if command -v bpftrace &>/dev/null; then
    echo "Running for 5 seconds..." >> ~/practice/bpftrace_maps.txt
    sudo timeout 5 bpftrace -e \
        'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); }' \
        2>/dev/null >> ~/practice/bpftrace_maps.txt || true
else
    cat >> ~/practice/bpftrace_maps.txt << 'EOF'
Command:
  sudo bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); }'

Expected output (printed when Ctrl-C is pressed):
  @[systemd]: 1423
  @[sshd]: 287
  @[bash]: 54
  @[kworker]: 12

How it works:
  - @[comm] is a map keyed by process name
  - count() increments the counter atomically
  - Map is printed automatically on exit
  - Use print(@, 10) to show only top 10
EOF
fi
```

## Task 2 — read() byte histogram (run or document)

```bash
echo "" >> ~/practice/bpftrace_maps.txt
echo "=== Map example 2: read() byte distribution ===" >> ~/practice/bpftrace_maps.txt

if command -v bpftrace &>/dev/null; then
    echo "Running for 5 seconds..." >> ~/practice/bpftrace_maps.txt
    sudo timeout 5 bpftrace -e \
        'tracepoint:syscalls:sys_exit_read /args.ret > 0/ { @bytes = hist(args.ret); }' \
        2>/dev/null >> ~/practice/bpftrace_maps.txt || true
else
    cat >> ~/practice/bpftrace_maps.txt << 'EOF'
Command:
  sudo bpftrace -e '
  tracepoint:syscalls:sys_exit_read /args.ret > 0/ {
      @bytes = hist(args.ret);
  }'

Expected output:
  @bytes:
  [1]            12 |@@                  |
  [2, 4)          4 |                    |
  [4, 8)          8 |@                   |
  [8, 16)        45 |@@@@@@@@            |
  [16, 32)       89 |@@@@@@@@@@@@@@@@@   |
  [32, 64)      120 |@@@@@@@@@@@@@@@@@@@@|
  [64, 128)      67 |@@@@@@@@@@@         |

How it works:
  - sys_exit_read fires when read() returns
  - args.ret is the return value (bytes read, or negative for errors)
  - /args.ret > 0/ filters out errors and EOF (0)
  - hist() creates power-of-2 buckets
EOF
fi
```

## Task 3 — vfs_read latency with lhist (document)

```bash
echo "" >> ~/practice/bpftrace_maps.txt
echo "=== Map example 3: vfs_read latency histogram ===" >> ~/practice/bpftrace_maps.txt
cat >> ~/practice/bpftrace_maps.txt << 'EOF'
Command:
  sudo bpftrace -e '
  kprobe:vfs_read    { @start[tid] = nsecs; }
  kretprobe:vfs_read /@start[tid]/ {
      @latency_us = lhist((nsecs - @start[tid]) / 1000, 0, 1000, 50);
      delete(@start[tid]);
  }'

Key concepts:
  @start[tid]       - per-thread timestamp (tid = thread ID, avoids cross-thread collision)
  /@start[tid]/     - guard filter: skip if we didn't see the entry (partial trace)
  nsecs - @start[]  - delta in nanoseconds
  / 1000            - convert to microseconds
  lhist(val, 0, 1000, 50) - linear histogram: 0-1000 us range, 50 us buckets
  delete(@start[tid]) - cleanup map entry to prevent unbounded growth

Why lhist over hist here?
  hist() uses power-of-2 buckets (1, 2-3, 4-7, 8-15, ...)
  lhist() uses equal-width buckets (0-50, 50-100, 100-150, ...)
  lhist is better when you know the expected range and want precise buckets
EOF
```

## Task 4 — Map aggregation reference

```bash
cat >> ~/practice/bpftrace_maps.txt << 'EOF'

=== bpftrace aggregation functions ===
count()                 - increment counter
sum(n)                  - running total
avg(n)                  - running average
min(n)                  - track minimum
max(n)                  - track maximum
hist(n)                 - power-of-2 histogram
lhist(n, min, max, step)- linear histogram
stats(n)                - count + avg + total combined

=== Map operations ===
@map[key] = value      - assign
@map[key] = count()    - aggregate
delete(@map[key])      - remove entry
clear(@map)            - remove all entries
print(@map)            - print map now (not at exit)
print(@map, 10)        - print top 10 entries
EOF
```

## Verification

```bash
grep -c "count()\|hist\|lhist" ~/practice/bpftrace_maps.txt
echo "aggregation function references found"
```
