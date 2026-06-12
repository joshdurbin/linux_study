# The OOM Killer and Memory Overcommit

When a Linux system runs out of memory, the kernel must decide what to kill. Understanding the OOM killer — how it selects victims, how to influence it, and how to read its forensics — is essential for any system running close to memory limits.

## Memory Overcommit

Linux defaults to **optimistic overcommit**: it grants more virtual memory than physical RAM exists, betting that most allocations will never all be used simultaneously. A process calling `malloc(1GB)` on a 512MB machine succeeds — the physical pages are only allocated when actually written.

```bash
# Overcommit mode
cat /proc/sys/vm/overcommit_memory
# 0 = heuristic overcommit (default): allow reasonable overcommit, reject obvious excess
# 1 = always overcommit: never refuse malloc() regardless of RAM
# 2 = never overcommit: refuse allocations exceeding RAM + swap * overcommit_ratio

cat /proc/sys/vm/overcommit_ratio    # percentage of RAM used as overcommit ceiling in mode 2
# default: 50 (so commit limit = swap + 50% of RAM)

# What is the current commit limit?
cat /proc/meminfo | grep -E "CommitLimit|Committed_AS"
# CommitLimit:    total memory that can be allocated
# Committed_AS:   total memory currently committed (promised but maybe not used)
```

### Choosing a Mode

| Mode | Use Case |
|------|---------|
| 0 (heuristic) | General purpose — allows fork() to succeed cheaply |
| 1 (always) | HPC, memory-mapped databases that manage their own pages |
| 2 (strict) | Systems where OOM kills are unacceptable; size RAM+swap carefully |

```bash
# Enable strict mode with generous ratio
sudo sysctl -w vm.overcommit_memory=2
sudo sysctl -w vm.overcommit_ratio=80   # can commit up to swap + 80% RAM
```

## OOM Score — How the Kernel Picks Victims

Every process has an `oom_score` (0–1000). Higher score = more likely to be killed.

```bash
# OOM score of the current process
cat /proc/$$/oom_score

# OOM scores for all processes, sorted
for pid in /proc/[0-9]*/oom_score; do
    score=$(cat $pid 2>/dev/null)
    comm=$(cat $(dirname $pid)/comm 2>/dev/null)
    echo "$score $comm"
done | sort -rn | head -20
```

The kernel computes `oom_score` from:
- RSS (resident memory): larger processes score higher
- `oom_score_adj` (adjustment set by userspace)
- Whether it's a child process of a scored-high parent

## oom_score_adj — Influencing the Victim Selection

```bash
# Adjustment range: -1000 (never kill) to +1000 (kill first)
cat /proc/$$/oom_score_adj   # 0 = no adjustment

# Protect a critical process (pid 1234) from OOM kills
echo -1000 | sudo tee /proc/1234/oom_score_adj

# Make a disposable process the first victim
echo 1000 | sudo tee /proc/$$/oom_score_adj

# Protect systemd (PID 1) — it does this to itself
cat /proc/1/oom_score_adj    # -1000

# Protect from a systemd service unit file
# [Service]
# OOMScoreAdjust=-900     ← systemd passes this to the kernel
```

## Reading an OOM Kill Event

OOM kills are logged to the kernel ring buffer:

```bash
dmesg | grep -A 20 "Out of memory"
journalctl -k | grep -A 20 "Out of memory"
```

A typical OOM kill message:
```
[12345.678] Out of memory: Kill process 4321 (myapp) score 872 or sacrifice child
[12345.679] Killed process 4321 (myapp) total-vm:2097152kB, anon-rss:1048576kB, ...
[12345.680] oom_reaper: reaped process 4321 (myapp), now anon-rss:0kB, ...
```

Fields to read:
- `score 872` — the oom_score at time of kill
- `total-vm` — virtual memory size (may be much larger than actual usage)
- `anon-rss` — anonymous resident pages (actual memory in RAM, not from files)
- `file-rss` — file-backed pages

### The OOM Memory Report

Before killing, the kernel prints a full memory snapshot:

```
Mem-Info:
active_anon:512M inactive_anon:256M isolated_anon:0
active_file:64M inactive_file:32M isolated_file:0
...
Tasks state (memory values in pages):
[pid]  uid  tgid  total_vm  rss  nr_ptes  swapents  oom_score_adj  name
 1234    0  1234   524288  262144    512       0             0     myapp
```

```bash
# Parse OOM kills from the journal
journalctl -k --no-pager | awk '/Out of memory/{print; for(i=0;i<5;i++){getline;print}}'
```

## cgroup-Level OOM

When a process exceeds a cgroup memory limit, the cgroup-level OOM killer fires (not the system-wide one):

```bash
# Set a memory limit for a cgroup
mkdir /sys/fs/cgroup/mytest
echo $((100 * 1024 * 1024)) > /sys/fs/cgroup/mytest/memory.max   # 100MB

# The process in this cgroup is killed when it hits 100MB
# The kill appears in dmesg:
dmesg | grep "oom-kill"
# oom-kill:constraint=CONSTRAINT_MEMCG,...,task_memcg=/mytest,...
```

`constraint=CONSTRAINT_MEMCG` distinguishes cgroup OOM from system-wide OOM.

## Preventing OOM Kills

```bash
# Add swap (buys time)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Tune swappiness (0-100): lower = prefer to keep RAM, less aggressive swapping
sysctl vm.swappiness    # default: 60
sudo sysctl -w vm.swappiness=10   # prefer RAM, only swap when necessary

# Monitor commit ratio
watch -n5 'awk "/CommitLimit|Committed_AS|MemFree|SwapFree/{print}" /proc/meminfo'

# Alert when Committed_AS approaches CommitLimit
awk '/CommitLimit/{limit=$2} /Committed_AS/{committed=$2}
     END {pct=committed*100/limit; printf "Commit: %.1f%%\n", pct}' /proc/meminfo
```

## Further Reading

- [Linux kernel MM concepts — kernel.org](https://www.kernel.org/doc/html/latest/admin-guide/mm/concepts.html) — kernel documentation covering overcommit modes, the OOM killer algorithm, `oom_score` calculation, and memory zones — the authoritative source for the tunables in this lesson.
- [proc(5) vm section — man7.org](https://man7.org/linux/man-pages/man5/proc.5.html) — documents every `/proc/sys/vm/` tunable including `overcommit_memory`, `overcommit_ratio`, `swappiness`, and all fields in `/proc/meminfo` used to assess OOM state.
- [LWN — Taming the OOM killer](https://lwn.net/Articles/391222/) — detailed analysis of the OOM killer's victim selection algorithm, the `oom_badness()` function, and the design trade-offs between fairness and protecting critical processes.
- [Julia Evans — Linux memory](https://jvns.ca/blog/2016/12/03/linux-memory-pressure/) — accessible explanation of page cache, memory pressure, `MemAvailable` vs `MemFree`, and how to interpret the kernel memory snapshot that precedes an OOM kill in `dmesg`.
