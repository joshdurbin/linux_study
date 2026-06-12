# CPU Analysis — Exercises

Complete these tasks in your terminal. All output goes to `~/practice/cpu_analysis.txt`.

## Setup

```bash
mkdir -p ~/practice
```

## Task 1 — Interpret load average

Run `uptime` and record the output. Then answer in your file:
- How many logical CPUs does the system have? (`nproc`)
- Is the 1-minute load average above, at, or below the CPU count?

```bash
uptime >> ~/practice/cpu_analysis.txt
nproc >> ~/practice/cpu_analysis.txt
```

## Task 2 — Identify top CPU consumers with top

Run `top` in batch mode and capture the top 10 processes sorted by CPU:

```bash
top -b -n 1 -o %CPU | head -20 >> ~/practice/cpu_analysis.txt
```

Write a one-line comment in the file naming the top CPU-consuming process.

## Task 3 — Per-CPU breakdown with mpstat

```bash
echo "=== mpstat per-CPU ===" >> ~/practice/cpu_analysis.txt
mpstat -P ALL 1 3 >> ~/practice/cpu_analysis.txt
```

Observe: are all CPUs roughly equally loaded, or is one core significantly busier?

## Task 4 — Run queue with vmstat

```bash
echo "=== vmstat run queue ===" >> ~/practice/cpu_analysis.txt
vmstat 1 5 >> ~/practice/cpu_analysis.txt
```

Note the `r` column. Is it consistently above the CPU count (saturation)?

## Task 5 — Per-process CPU with pidstat

```bash
echo "=== pidstat top processes ===" >> ~/practice/cpu_analysis.txt
pidstat -u 1 3 >> ~/practice/cpu_analysis.txt
```

Add a comment: which process had the highest `%CPU` in the pidstat output?

## Verification

```bash
cat ~/practice/cpu_analysis.txt
```

The file should contain output from all four tools plus your observations.
