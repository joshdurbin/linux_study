# cgroups and Container Resource Limits

## What Are cgroups?

**Control groups (cgroups)** are a Linux kernel feature that organizes processes into hierarchical groups and applies resource limits, accounting, and isolation to those groups. Containers use cgroups to enforce CPU, memory, and I/O limits.

**cgroup v2** (the unified hierarchy) is the current standard — all resource controllers live under a single tree at `/sys/fs/cgroup`. Ubuntu 22.04+ and recent Kubernetes clusters use cgroup v2 by default.

## The cgroup v2 Hierarchy

```bash
# Root of the unified hierarchy
ls /sys/fs/cgroup/

# Key files at the root
cat /sys/fs/cgroup/cgroup.controllers    # available controllers
cat /sys/fs/cgroup/cgroup.subtree_control  # enabled controllers for children
```

## Creating a cgroup Manually

```bash
# Create a new cgroup slice for an app
sudo mkdir /sys/fs/cgroup/myapp

# Key resource files are created automatically:
ls /sys/fs/cgroup/myapp/
# cgroup.procs  memory.max  memory.current  cpu.weight  cpu.max  ...
```

## Setting Resource Limits

```bash
# Memory limit (hard limit — OOM kill if exceeded)
echo "104857600" | sudo tee /sys/fs/cgroup/myapp/memory.max   # 100 MiB in bytes
# Or using M suffix (kernel >= 5.something supports this):
echo "100M" | sudo tee /sys/fs/cgroup/myapp/memory.max

# Read current memory usage
cat /sys/fs/cgroup/myapp/memory.current

# CPU weight (relative share, default 100, range 1-10000)
echo "50" | sudo tee /sys/fs/cgroup/myapp/cpu.weight   # half the default weight

# CPU bandwidth limit (quota/period in microseconds)
# Allow 50ms of CPU every 100ms (50% of one CPU core)
echo "50000 100000" | sudo tee /sys/fs/cgroup/myapp/cpu.max
```

## Assigning Processes

```bash
# Add a running process to the cgroup
echo $$ | sudo tee /sys/fs/cgroup/myapp/cgroup.procs

# See which processes are in the cgroup
cat /sys/fs/cgroup/myapp/cgroup.procs

# See which cgroup the current process is in
cat /proc/self/cgroup       # cgroup v2: single line starting with "0::"
```

## Inspecting the Hierarchy

```bash
# Visualize the cgroup tree with systemd
systemd-cgls

# Show resource usage per cgroup
systemd-cgtop

# Find your own cgroup path
cat /proc/self/cgroup
# Output example: 0::/user.slice/user-1000.slice/session-2.scope
```

## How Docker and Kubernetes Use cgroups

Docker sets cgroup limits from `docker run` flags:

```bash
docker run --memory="100m" --cpus="0.5" --name mycontainer nginx
# Equivalent cgroup created at:
# /sys/fs/cgroup/system.slice/docker-<id>.scope/
```

Kubernetes translates pod resource requests and limits into cgroup settings:

```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "250m"
  limits:
    memory: "128Mi"
    cpu: "500m"
```

- `limits.memory` → `memory.max`
- `limits.cpu` → `cpu.max` (quota/period)
- `requests.cpu` → `cpu.weight`

## Key Takeaways

- cgroup v2 provides a unified tree at `/sys/fs/cgroup`.
- Create a cgroup with `mkdir`, set limits by writing to controller files.
- Assign processes by writing their PID to `cgroup.procs`.
- `cpu.weight` is relative scheduling weight; `cpu.max` sets hard bandwidth limits.
- `memory.max` triggers OOM kill when exceeded; `memory.high` is the soft limit.
- `systemd-cgls` and `systemd-cgtop` are your primary inspection tools.
- Docker and Kubernetes both translate their resource configs into cgroup v2 files.

## Further Reading

- [kernel.org: Control Group v2](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html) — The authoritative cgroup v2 documentation covering the unified hierarchy, controller enable/disable via `cgroup.subtree_control`, `memory.max`/`memory.high`, `cpu.max`, `cpu.weight`, and PSI integration.
- [cgroups(7) man page](https://man7.org/linux/man-pages/man7/cgroups.7.html) — Documents cgroup v1 and v2 hierarchy semantics, the difference between `memory.max` (hard kill) and `memory.high` (soft throttle), and the migration path from v1 to the unified v2 hierarchy.
- [LWN: Control groups series](https://lwn.net/Articles/604609/) — LWN's multi-part series covering cgroup v1 design flaws, the motivation for v2's unified hierarchy, and how controllers like `cpu.max` replace v1's complex scheduler tuning.
- [systemd resource control documentation](https://www.freedesktop.org/software/systemd/man/latest/systemd.resource-control.html) — Documents how systemd exposes cgroup v2 through `MemoryMax=`, `CPUQuota=`, and `CPUWeight=` in service unit files — the production interface for the same cgroup files shown in this lesson.
