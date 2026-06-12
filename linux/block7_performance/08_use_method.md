# The USE Method

## Definition

The USE Method, developed by Brendan Gregg, provides a systematic framework for performance analysis. For every **resource**, check three metrics:

- **U — Utilization**: the percentage of time the resource is busy doing work
- **S — Saturation**: the degree to which the resource has extra work it can't service, often queued
- **E — Errors**: error events (whether or not they affect performance)

The method is deliberately resource-first, not symptom-first. You enumerate all system resources, check USE for each, and investigate anomalies. This avoids the tunnel vision of jumping straight to one tool.

## Resources to Check

| Resource | Utilization | Saturation | Errors |
|----------|-------------|------------|--------|
| CPU | `mpstat %usr+%sys` | run queue length (`vmstat r`) | `dmesg` MCE events |
| Memory | pages used vs total | paging/swapping (`vmstat si/so`) | OOM events in `dmesg` |
| Network interface | bytes/s ÷ interface speed | send/recv queue drops | `ip -s link` errors, `netstat -s` |
| Storage device | `iostat %util` | I/O queue depth (`iostat avgqu-sz`) | `dmesg` I/O errors |
| File descriptors | open FDs ÷ `ulimit -n` | (rarely applicable) | EMFILE errors in `strace` |

## Saturation Indicators

| Resource | Saturation Signal |
|----------|------------------|
| CPU | `vmstat r` > number of CPUs |
| Memory | `vmstat si` or `so` > 0 (swapping) |
| Disk | `iostat avgqu-sz` > 1 (queue depth > 1) |
| Network TX | `ip -s link` TX dropped > 0 |

## Error Sources

```bash
# Kernel errors and hardware events
dmesg -T | tail -50
dmesg -T | grep -iE 'error|warn|fail|oom|killed'

# System log
grep -iE 'error|crit|alert|emerg' /var/log/syslog | tail -20

# Network error counters
netstat -s | grep -i error
ip -s link show eth0    # RX/TX errors, dropped, overrun

# Disk errors
dmesg | grep -iE '(sda|vda|nvme).*error'
```

## The First 60 Seconds Checklist

A practical checklist from Brendan Gregg and Netflix for initial triage of a performance problem:

```bash
# 1. Check load average trend
uptime

# 2. Kernel messages (errors, hardware events)
dmesg -T | tail -20

# 3. System-wide statistics
vmstat 1 5

# 4. Per-CPU breakdown
mpstat -P ALL 1 3

# 5. Per-process CPU
pidstat 1 3

# 6. Disk I/O
iostat -xz 1 3

# 7. Memory
free -h

# 8. Historical data (if sar is configured)
sar -n DEV 1 3    # network
sar -b 1 3        # I/O

# 9. Top processes
top -b -n 1
```

## Applying USE Systematically

Start with `vmstat 1` — it gives a bird's eye view of CPUs (r, us, sy, id, wa), memory (swpd, free, si, so), and I/O (bi, bo) in one output.

Then drill into the resource that shows saturation or high utilization:
- CPU saturated? → `mpstat`, `pidstat`, `perf top`
- Memory swapping? → `free`, `/proc/meminfo`, `sar -B`
- I/O bottleneck? → `iostat -xz`, `iotop`, `biolatency` (BCC)
- Network drops? → `ip -s link`, `netstat -s`, `ss -s`

## RED Method (Companion for Services)

For measuring service health (as opposed to resource health), use RED:
- **R — Rate**: requests per second
- **E — Errors**: failed requests per second
- **D — Duration**: distribution of response time

USE is for infrastructure resources; RED is for service-level monitoring. Together they cover both layers.

## Further Reading

- [Brendan Gregg: USE method](https://www.brendangregg.com/usemethod.html) — The original USE method article by Brendan Gregg, defining utilization, saturation, and errors for each resource type and explaining why resource-first analysis is faster than symptom-chasing.
- [Brendan Gregg: USE method Linux checklist](https://www.brendangregg.com/USEmethod/use-linux.html) — A complete per-resource checklist mapping each Linux tool (`mpstat`, `iostat`, `ss`) to the specific USE metric it measures — a direct companion to the table in this lesson.
- [Weave Works: The RED method](https://www.weave.works/blog/the-red-method-key-metrics-for-microservices-architecture/) — Introduces the RED method (Rate, Errors, Duration) for service-level monitoring, the complement to USE for infrastructure-level analysis described at the end of this lesson.
- [Google SRE Book: Monitoring distributed systems](https://sre.google/sre-book/monitoring-distributed-systems/) — The Google SRE chapter covering the Four Golden Signals, white-box vs black-box monitoring, and how alerting strategy relates to the USE/RED frameworks covered in this lesson.
