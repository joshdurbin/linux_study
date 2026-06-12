# USE Method — Exercises

Run the "first 60 seconds" diagnostic checklist and record all output in `~/practice/use_method_output.txt`.

## Setup

```bash
mkdir -p ~/practice
```

## Task 1 — uptime (load average)

```bash
echo "=== 1. uptime ===" >> ~/practice/use_method_output.txt
uptime >> ~/practice/use_method_output.txt
```

## Task 2 — dmesg (kernel errors)

```bash
echo "=== 2. dmesg (last 10 lines) ===" >> ~/practice/use_method_output.txt
dmesg -T 2>/dev/null | tail -10 >> ~/practice/use_method_output.txt || dmesg | tail -10 >> ~/practice/use_method_output.txt
```

## Task 3 — vmstat (system-wide overview)

```bash
echo "=== 3. vmstat 1 5 ===" >> ~/practice/use_method_output.txt
vmstat 1 5 >> ~/practice/use_method_output.txt
```

Interpret the `r` column (run queue) and `si`/`so` columns (swap in/out).

## Task 4 — mpstat (per-CPU)

```bash
echo "=== 4. mpstat -P ALL 1 3 ===" >> ~/practice/use_method_output.txt
mpstat -P ALL 1 3 >> ~/practice/use_method_output.txt
```

## Task 5 — pidstat (per-process CPU)

```bash
echo "=== 5. pidstat 1 3 ===" >> ~/practice/use_method_output.txt
pidstat 1 3 >> ~/practice/use_method_output.txt
```

## Task 6 — iostat (I/O)

```bash
echo "=== 6. iostat -xz 1 3 ===" >> ~/practice/use_method_output.txt
iostat -xz 1 3 >> ~/practice/use_method_output.txt
```

## Task 7 — free (memory)

```bash
echo "=== 7. free -h ===" >> ~/practice/use_method_output.txt
free -h >> ~/practice/use_method_output.txt
```

## Task 8 — network errors

```bash
echo "=== 8. ip -s link ===" >> ~/practice/use_method_output.txt
ip -s link >> ~/practice/use_method_output.txt
```

## Task 9 — top snapshot

```bash
echo "=== 9. top snapshot ===" >> ~/practice/use_method_output.txt
top -b -n 1 | head -20 >> ~/practice/use_method_output.txt
```

## Task 10 — Write your USE assessment

Based on the output above, fill in this template:

```bash
cat >> ~/practice/use_method_output.txt << 'EOF'
=== USE Method Assessment ===
CPU:
  Utilization (mpstat %usr+%sys):
  Saturation (vmstat r > nproc?):
  Errors (dmesg MCE?):

Memory:
  Utilization (free -h used vs total):
  Saturation (vmstat si/so > 0?):
  Errors (OOM in dmesg?):

Disk I/O:
  Utilization (iostat %util):
  Saturation (iostat avgqu-sz > 1?):
  Errors (dmesg disk errors?):

Network:
  Utilization (approx):
  Saturation (ip -s link drops > 0?):
  Errors (ip -s link errors > 0?):
EOF
```

## Verification

```bash
grep -i "load average" ~/practice/use_method_output.txt
```
