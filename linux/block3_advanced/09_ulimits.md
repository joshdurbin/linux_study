# ulimits and Resource Limits

"Too many open files" is one of the most common production incidents. It's caused by per-process resource limits hitting their ceiling. Understanding ulimits, where they're set, and how to tune them correctly prevents an entire class of production outages.

## What ulimits Control

The kernel enforces per-process resource limits. Each process inherits limits from its parent. Shell and login processes get their initial limits from PAM.

```bash
# View all limits for the current shell
ulimit -a

# Key limits:
# open files (-n)    — max file descriptors (sockets count as FDs)
# max processes (-u) — max processes/threads this user can create
# stack size (-s)    — stack size per thread
# virtual memory (-v)— max virtual address space
# core file size (-c)— core dump size (0 = no core dumps)
# max locked mem (-l)— max bytes locked into RAM (needed by Redis, databases)
```

## Two Tiers: Soft and Hard

| Tier | Meaning | Who Can Change It |
|------|---------|------------------|
| **Soft** | Current enforced limit | Process itself can raise up to the hard limit |
| **Hard** | Ceiling for the soft limit | Only root can raise |

```bash
ulimit -Sn    # soft limit for open files
ulimit -Hn    # hard limit for open files

# Raise soft limit to hard limit (no root required)
ulimit -n $(ulimit -Hn)

# Set both soft and hard (requires root if raising the hard limit)
sudo -i
ulimit -n 1048576     # sets both soft and hard in the current shell
```

## The "Too Many Open Files" Error

```bash
# Diagnose: how many FDs is a process actually using?
ls /proc/$(pgrep nginx | head -1)/fd | wc -l

# What's the limit for that process?
cat /proc/$(pgrep nginx | head -1)/limits | grep "open files"

# System-wide FD usage
cat /proc/sys/fs/file-nr
# 3456  0  524288
# used  unused  max (kernel-wide ceiling)

# Increase kernel-wide ceiling
sudo sysctl -w fs.file-max=1048576
```

## /etc/security/limits.conf — PAM-Based Limits

These limits apply to login sessions (SSH, TTY, su). Syntax: `<domain> <type> <item> <value>`

```bash
# View current limits config
cat /etc/security/limits.conf

# Add high-limit config for a service user
sudo tee /etc/security/limits.d/myapp.conf << 'EOF'
# domain     type   item         value
myapp        soft   nofile       65536
myapp        hard   nofile       131072
myapp        soft   nproc        8192
myapp        hard   nproc        16384
*            soft   core         0         # no core dumps for anyone
root         soft   nofile       65536
root         hard   nofile       131072
EOF
```

Changes take effect on next login/session. Verify after login:
```bash
su - myapp -c 'ulimit -n'
```

### /etc/security/limits.d/

Drop-in files in this directory are loaded after `limits.conf` and override it. Prefer this over editing `limits.conf` directly.

## systemd Services: LimitNOFILE

PAM limits don't apply to systemd services. systemd manages its own limits via unit file directives:

```ini
[Service]
LimitNOFILE=65536       # open files
LimitNPROC=512          # child processes
LimitMEMLOCK=infinity   # locked memory (needed by Redis, Elasticsearch)
LimitCORE=0             # no core dumps
```

```bash
# Check effective limits of a running systemd service
PID=$(systemctl show -p MainPID nginx.service | cut -d= -f2)
cat /proc/$PID/limits

# Override without editing the unit file
sudo systemctl edit nginx.service    # creates a drop-in override
# Add:
# [Service]
# LimitNOFILE=131072
sudo systemctl daemon-reload && sudo systemctl restart nginx
```

## prlimit — Get/Set Limits of Running Processes

```bash
# View limits of a running process
prlimit --pid $(pgrep nginx | head -1)

# Change the limit of a running process (Linux 3.2+)
sudo prlimit --pid $(pgrep nginx | head -1) --nofile=131072:131072

# Set limits for a command you're about to run
prlimit --nofile=131072 ./my_server
```

## Common Tuning Scenarios

### High-connection servers (nginx, Redis, databases)

```bash
# nginx handles thousands of connections — each is an FD
# Rule of thumb: worker_processes * worker_connections * 2 + 100
# For 4 workers × 10000 connections: 80100 FDs

# /etc/systemd/system/nginx.service.d/override.conf
[Service]
LimitNOFILE=131072
```

### Java applications

```bash
# JVM needs FDs for: threads, sockets, class files, JMX
# Minimum: 65536 for any production JVM
ulimit -n 65536

# Check current Java process FD usage
ls -la /proc/$(pgrep java | head -1)/fd | wc -l
```

### Default systemd limits

```bash
# Default limits for all systemd services can be changed in:
# /etc/systemd/system.conf  (system services)
# /etc/systemd/user.conf    (user services)

# [Manager]
# DefaultLimitNOFILE=65536

sudo grep -i "DefaultLimit" /etc/systemd/system.conf
```

## Diagnosing Limit Exhaustion

```bash
# Check kernel log for limit-related messages
dmesg | grep -i "too many open\|file-max\|out of file\|EMFILE"
journalctl -k | grep -iE "EMFILE|ENFILE|too many"

# Find the process using the most FDs
for pid in /proc/[0-9]*/fd; do
    count=$(ls $pid 2>/dev/null | wc -l)
    echo "$count $pid"
done | sort -rn | head -10 | while read count fddir; do
    pid=$(echo $fddir | cut -d/ -f3)
    comm=$(cat /proc/$pid/comm 2>/dev/null)
    limit=$(awk '/open files/{print $4}' /proc/$pid/limits 2>/dev/null)
    echo "PID $pid ($comm): $count FDs open / $limit limit"
done
```

## Further Reading

- [getrlimit(2) — man7.org](https://man7.org/linux/man-pages/man2/getrlimit.2.html) — authoritative reference for every `RLIMIT_*` constant (`RLIMIT_NOFILE`, `RLIMIT_NPROC`, `RLIMIT_STACK`, `RLIMIT_MEMLOCK`), soft/hard semantics, and how the kernel enforces each limit.
- [prlimit(1) — man7.org](https://man7.org/linux/man-pages/man1/prlimit.1.html) — documents the `prlimit` utility for reading and changing resource limits of running processes live, including the underlying `prlimit(2)` syscall introduced in Linux 3.2.
- [limits.conf(5) — man7.org](https://man7.org/linux/man-pages/man5/limits.conf.5.html) — complete reference for `/etc/security/limits.conf` and `/etc/security/limits.d/` syntax, domain matching rules (`*`, `%group`, `@group`), and the PAM module that applies them.
- [systemd.exec(5) — freedesktop.org](https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html) — documents `LimitNOFILE`, `LimitNPROC`, `LimitMEMLOCK`, and all other `Limit*` directives for systemd services, which bypass PAM-based limits entirely.
