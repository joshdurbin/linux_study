# cgroups v2

## What Are cgroups?

**Control Groups (cgroups)** are a Linux kernel feature for organizing processes into hierarchical groups and applying resource limits, accounting, and controls to those groups.

cgroups answer questions like:
- "Limit this web server to 4GB RAM and 2 CPU cores"
- "Guarantee this database gets at least 40% CPU"
- "Kill any process in this group that tries to fork more than 100 processes"

## v1 vs v2

- **cgroups v1** (legacy): Each resource controller (`memory`, `cpu`, `blkio`, `pids`) had its own hierarchy mounted separately. Confusing and inconsistent.
- **cgroups v2** (modern, unified): Single hierarchy at `/sys/fs/cgroup`. All controllers operate on the same tree. Ubuntu 22.04+ uses v2 by default.

```bash
# Confirm v2 is in use
mount | grep cgroup
# cgroup2 on /sys/fs/cgroup type cgroup2 (rw,nosuid,nodev,noexec,relatime,nsdelegate,memory_recursiveprot)

# Check cgroup version
cat /proc/filesystems | grep cgroup
```

## The Unified Hierarchy

```bash
# The root cgroup
ls /sys/fs/cgroup/

# Key files at the root
cat /sys/fs/cgroup/cgroup.controllers    # available controllers
cat /sys/fs/cgroup/cgroup.subtree_control # controllers enabled for children

# systemd organizes everything under system.slice, user.slice, etc.
ls /sys/fs/cgroup/system.slice/
ls /sys/fs/cgroup/user.slice/
```

## Controllers

| Controller | File Interface | Controls |
|-----------|---------------|---------|
| `memory` | `memory.max`, `memory.current` | RAM usage |
| `cpu` | `cpu.weight`, `cpu.max` | CPU time |
| `io` | `io.max`, `io.weight` | Block I/O bandwidth |
| `pids` | `pids.max`, `pids.current` | Number of processes |

## Finding Your Process's cgroup

```bash
# Every process has a cgroup assignment
cat /proc/self/cgroup
# 0::/user.slice/user-1000.slice/session-1.scope

# PID 1 (systemd) is at the root
cat /proc/1/cgroup
# 0::/init.scope
```

## Exploring the cgroup Tree

```bash
# Navigate your current cgroup
MYCG=$(cat /proc/self/cgroup | cut -d: -f3)
echo "My cgroup: $MYCG"
echo "Full path: /sys/fs/cgroup$MYCG"

# List files in your cgroup
ls /sys/fs/cgroup$MYCG

# Check memory usage of your session
cat /sys/fs/cgroup$MYCG/memory.current 2>/dev/null || echo "no memory stats here"

# Check pids in your cgroup
cat /sys/fs/cgroup$MYCG/pids.current 2>/dev/null
```

## Creating a cgroup and Setting Limits

```bash
# Create a new cgroup (as root)
sudo mkdir /sys/fs/cgroup/mytest

# Enable controllers for this cgroup
echo "+memory +pids" | sudo tee /sys/fs/cgroup/mytest/cgroup.subtree_control

# Create a child cgroup with limits
sudo mkdir /sys/fs/cgroup/mytest/limited

# Set memory limit to 64MB
echo "67108864" | sudo tee /sys/fs/cgroup/mytest/limited/memory.max

# Set pids limit
echo "20" | sudo tee /sys/fs/cgroup/mytest/limited/pids.max

# Run a process in this cgroup
# Method 1: write PID to cgroup.procs
bash -c 'echo $$ | sudo tee /sys/fs/cgroup/mytest/limited/cgroup.procs; exec sleep 60' &
LPID=$!

# Verify it's in the cgroup
cat /proc/$LPID/cgroup

# Clean up
kill $LPID
sudo rmdir /sys/fs/cgroup/mytest/limited
sudo rmdir /sys/fs/cgroup/mytest
```

## systemd and cgroups

systemd is the cgroup manager on modern Linux. Every service, user session, and scope gets its own cgroup:

```bash
# View the cgroup tree via systemd
systemctl status
systemd-cgls

# Check resource usage by cgroup
systemd-cgtop

# Set resource limits via systemd (transient)
systemd-run --scope --property=MemoryMax=100M --property=CPUQuota=50% bash

# Permanent limits in a service unit
# [Service]
# MemoryMax=1G
# CPUQuota=200%   (200% = 2 full cores)
```

## Memory Controller in Detail

```bash
# Navigate to a systemd service's cgroup
SERVICE_CG=$(systemctl show -P ControlGroup sshd.service 2>/dev/null)
if [ -n "$SERVICE_CG" ]; then
    echo "sshd cgroup: $SERVICE_CG"
    cat /sys/fs/cgroup$SERVICE_CG/memory.current  # current usage in bytes
    cat /sys/fs/cgroup$SERVICE_CG/memory.max      # limit (max = unlimited)
fi

# OOM behavior when memory.max is exceeded: process is killed
# memory.oom.group = 1 kills all processes in group together
```

## CPU Controller

```bash
# cpu.weight: relative weight (default 100, range 1-10000)
# Higher weight = more CPU when contested

# cpu.max: hard limit
# Format: "quota_us period_us"
# e.g., "200000 1000000" = 200ms per 1s = 20% of one CPU
# "max 1000000" = unlimited

cat /sys/fs/cgroup/system.slice/cpu.weight 2>/dev/null
```

## Further Reading

- [cgroups v2 — kernel.org](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html) — the authoritative kernel documentation for cgroups v2: the unified hierarchy, controller enablement, delegation model, and the full interface for every controller (`memory`, `cpu`, `io`, `pids`).
- [cgroups(7) — man7.org](https://man7.org/linux/man-pages/man7/cgroups.7.html) — man page covering v1 vs v2 differences, cgroup namespace, the `cgroup.procs` / `cgroup.threads` interface, and how systemd delegates the cgroup tree.
- [LWN — Control groups v2](https://lwn.net/Articles/679786/) — LWN deep-dive into the v2 unified hierarchy design, why v1's per-controller hierarchies were problematic, and the new delegation model that makes containerization cleaner.
- [systemd.resource-control(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.resource-control.html) — documents every systemd cgroup directive: `MemoryMax`, `CPUQuota`, `IOWeight`, `TasksMax`, and how they map to cgroup v2 controller files.
