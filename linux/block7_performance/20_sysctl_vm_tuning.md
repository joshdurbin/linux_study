# sysctl VM Tuning

The Linux VM subsystem exposes dozens of tunable parameters through `sysctl`. Getting these right separates a system that performs well under load from one that stutters, thrashes, or OOM-kills processes at the worst possible moment.

This lesson covers the parameters that matter most for production workloads: databases, containerized applications, and high-memory services.

## The Big Picture: What You're Tuning

The kernel memory subsystem makes continuous tradeoffs between:

1. **Keeping hot data in page cache** (fast reads) vs. **freeing memory for new allocations**
2. **Batching dirty page writes** (reduce I/O syscalls) vs. **bounding write-back lag** (reduce latency spikes)
3. **Using swap to extend the working set** vs. **keeping everything in RAM** (reduce latency)

Defaults are conservative and work reasonably everywhere. Production tuning means shifting these tradeoffs toward your specific workload.

## Viewing and Setting sysctl Parameters

```bash
# Read a single parameter
sysctl vm.swappiness

# Read all vm.* parameters
sysctl -a 2>/dev/null | grep '^vm\.'

# Set temporarily (lost on reboot)
sysctl -w vm.swappiness=10

# Set at runtime via /proc/sys (equivalent)
echo 10 > /proc/sys/vm/swappiness

# Persist across reboots
cat >> /etc/sysctl.d/99-custom.conf <<'EOF'
vm.swappiness = 10
vm.dirty_ratio = 15
EOF
sysctl -p /etc/sysctl.d/99-custom.conf
```

## vm.swappiness

**Default: 60**

Controls the kernel's tendency to swap anonymous memory (heap, stack) to disk vs. reclaiming page cache.

```
0    Never swap unless absolutely necessary (OOM imminent).
     Kernel aggressively reclaims page cache instead.
     Risk: OOM kills if working set exceeds RAM.

10   Low swap pressure. Kernel prefers reclaiming cache.
     Recommended for database servers (keep working set in RAM).

60   Default. Balanced: some swap, some cache reclaim.

100  Swap aggressively. Kernel may swap active memory to
     make room for page cache. Rarely useful on servers.
```

**Database servers**: `vm.swappiness=1` or `vm.swappiness=10`
- PostgreSQL, MySQL, Redis benefit massively from keeping their buffer pools in RAM
- A single swap event can cause 100ms+ query latency

**Container hosts**: `vm.swappiness=0` or `vm.swappiness=10`
- Individual containers set their own memory limits; host swapping bypasses those

**Note**: `swappiness=0` does not disable swap — it just makes the kernel very reluctant. To fully disable swap: `swapoff -a`.

## vm.dirty_ratio and vm.dirty_background_ratio

These control when the kernel writes dirty (modified) pages to disk.

```
vm.dirty_background_ratio = 10   (default)
vm.dirty_ratio = 20               (default)
```

**dirty_background_ratio**: When dirty pages reach this percentage of total memory, kernel background writeback (`pdflush`/`kworker`) kicks in — *asynchronously*. Applications continue running.

**dirty_ratio**: Hard limit. When dirty pages reach this percentage of total memory, *any process that tries to write* is blocked (throttled) until writeback catches up. This causes write latency spikes.

```
                         dirty_background_ratio      dirty_ratio
                                |                        |
Dirty pages (% RAM): 0%--------10%----..................20%--------30%
                                |                        |
                                background writeback     WRITERS BLOCKED
                                starts (async)           (hard throttle)
```

**Database servers** (heavy write workloads):
```
vm.dirty_ratio = 5
vm.dirty_background_ratio = 2
```
Lower values mean more frequent writeback, reducing the maximum latency spike when the hard limit triggers.

**High-write throughput** (log aggregation, analytics):
```
vm.dirty_ratio = 40
vm.dirty_background_ratio = 20
```
Higher values allow more buffering, improving burst write throughput at the cost of larger potential latency spikes.

### Absolute values (bytes) — preferred for large-RAM systems

On systems with 256GB+ RAM, percentage-based limits can allow enormous dirty page accumulations (20% of 256GB = 51GB). Use absolute byte limits instead:

```bash
# /proc/sys/vm/dirty_bytes and dirty_background_bytes take priority over ratios
sysctl -w vm.dirty_bytes=$((2 * 1024 * 1024 * 1024))            # 2GB
sysctl -w vm.dirty_background_bytes=$((512 * 1024 * 1024))      # 512MB
```

When `dirty_bytes` is set, `dirty_ratio` is ignored.

## vm.dirty_expire_centisecs and vm.dirty_writeback_centisecs

```
vm.dirty_expire_centisecs = 3000    (default = 30 seconds)
vm.dirty_writeback_centisecs = 500  (default = 5 seconds)
```

**dirty_writeback_centisecs**: How often the kernel wakes writeback threads to flush dirty pages. Lower = more frequent flushes = more I/O overhead, lower write-back lag.

**dirty_expire_centisecs**: How old a dirty page must be before writeback considers it "expired" and flushes it regardless of dirty ratio. Prevents stale dirty pages from sitting in memory indefinitely.

For databases or apps requiring low write-back latency:
```
vm.dirty_expire_centisecs = 1000    # 10 seconds
vm.dirty_writeback_centisecs = 100  # 1 second
```

## vm.vfs_cache_pressure

**Default: 100**

Controls the kernel's tendency to reclaim inode and dentry cache (the data structures representing filesystem metadata — file names, directory entries) relative to page cache.

```
50    Kernel is very reluctant to evict inode/dentry cache.
      Good for workloads with many small files (source code, logs).
      Risk: inode cache can grow large, consuming RAM.

100   Default balanced behavior.

200   Aggressively reclaim inode/dentry cache in favor of page cache.
      Useful on systems with very large filesystems and huge RAM.
```

Workloads with millions of files (mail servers, artifact storage):
```
vm.vfs_cache_pressure = 50
```

## vm.min_free_kbytes

**Default: Calculated at boot (~0.4% of RAM, min 128KB)**

The amount of RAM the kernel keeps in a "free" reserve at all times. The allocator will reclaim pages before dipping below this threshold.

Too low: OOM killer triggers before the system can gracefully handle memory pressure.
Too high: Wastes memory that could be used for cache.

For systems with 64GB+ RAM:
```
vm.min_free_kbytes = 1048576    # 1 GB reserve
```

This gives the kernel time to react to memory pressure before OOM.

## vm.zone_reclaim_mode

**Default: 0 on most systems**

On NUMA systems (multiple CPU sockets), controls whether the kernel reclaims memory from the local NUMA zone before allocating from a remote zone.

```
0    Default. Allocate from any NUMA zone freely.
     Best for most workloads — avoids memory stalls.

1    Reclaim local zone memory before going remote.
     Can improve local memory bandwidth for NUMA-sensitive apps.
     Risk: causes stalls if local zone is under heavy pressure.

4    Reclaim dirty pages on local zone reclaim.
```

For most containerized and cloud workloads, leave at `0`.
For high-performance HPC workloads with explicit NUMA affinity (see block7/14_numa), consider `1`.

## kernel.pid_max

**Default: 32768 (or 4194304 on 64-bit systems with ASLR)**

Maximum number of process IDs. Each PID consumes a small amount of kernel memory.

Container environments spawn and destroy processes constantly. With many containers running many short-lived processes (health checks, init scripts), PID exhaustion causes `fork: Resource temporarily unavailable`.

```bash
# Check current usage
cat /proc/sys/kernel/pid_max
ls /proc | grep '^[0-9]' | wc -l     # current PID count
```

For container hosts:
```
kernel.pid_max = 4194304    # maximum on 64-bit
```

## fs.file-max

**Default: ~1.6 million (varies by RAM)**

System-wide ceiling on open file descriptors. This is distinct from per-process limits (`ulimit -n` / `nofile` in limits.conf).

When this limit is hit, any process trying to `open()` a file gets `ENFILE: Too many open files in system`.

```bash
# Current system-wide FD usage
cat /proc/sys/fs/file-nr   # used / unused / max
```

For database servers or high-connection network services:
```
fs.file-max = 2097152
```

Also set per-process limits in `/etc/security/limits.conf`:
```
*    soft    nofile    1048576
*    hard    nofile    1048576
```

## kernel.threads-max

**Default: Calculated from RAM (~50 threads per MB of RAM)**

System-wide ceiling on total threads (tasks in the scheduler). When hit, `pthread_create()` fails with `EAGAIN`.

Relevant for Java applications (which create many threads) and container environments:
```
kernel.threads-max = 4194304
```

## Reading /proc/vmstat

`/proc/vmstat` exposes the kernel's VM event counters. It's the ground truth for what's actually happening in the memory subsystem.

```bash
cat /proc/vmstat
```

Key fields:

```
pswpin       Pages swapped in (read from swap) — non-zero means you're swapping
pswpout      Pages swapped out (written to swap)
pgpgin       Pages read from disk (page-in events)
pgpgout      Pages written to disk (page-out events)
pgfault      Minor page faults (page not present but in address space)
pgmajfault   Major page faults (page not present, must read from disk)
nr_dirty     Currently dirty pages (not yet written to disk)
nr_writeback Currently being written back to disk
pgsteal_*    Pages reclaimed from various LRU lists
pgscan_*     Pages scanned during reclaim
```

**Watching for swap pressure**:
```bash
# Sample pswpin/pswpout over time
prev_in=$(awk '/^pswpin/{print $2}' /proc/vmstat)
prev_out=$(awk '/^pswpout/{print $2}' /proc/vmstat)
sleep 5
curr_in=$(awk '/^pswpin/{print $2}' /proc/vmstat)
curr_out=$(awk '/^pswpout/{print $2}' /proc/vmstat)
echo "Swap-in/5s: $((curr_in - prev_in)) pages"
echo "Swap-out/5s: $((curr_out - prev_out)) pages"
```

**Watching dirty page accumulation**:
```bash
watch -n 1 'awk "/^nr_dirty|^nr_writeback|^pswpin|^pswpout/{print}" /proc/vmstat'
```

**Major faults** (pgmajfault) indicate pages being read from disk — a sustained high rate means your working set exceeds physical RAM.

## Tuning Profiles

### Database Server Profile
```ini
# /etc/sysctl.d/99-database.conf
vm.swappiness = 1
vm.dirty_ratio = 5
vm.dirty_background_ratio = 2
vm.dirty_expire_centisecs = 1000
vm.dirty_writeback_centisecs = 100
vm.vfs_cache_pressure = 50
vm.min_free_kbytes = 1048576
kernel.pid_max = 4194304
fs.file-max = 2097152
```

Rationale:
- Low swappiness keeps buffer pool in RAM
- Low dirty ratios prevent write stall spikes
- Larger min_free prevents OOM surprises
- Higher file-max for connection FDs

### Containerized Application Host
```ini
# /etc/sysctl.d/99-container-host.conf
vm.swappiness = 10
vm.dirty_ratio = 20
vm.dirty_background_ratio = 10
kernel.pid_max = 4194304
fs.file-max = 2097152
kernel.threads-max = 4194304
```

### Desktop / Development Machine
```ini
# /etc/sysctl.d/99-desktop.conf
vm.swappiness = 60      # More aggressive swap is fine — latency less critical
vm.vfs_cache_pressure = 50  # Keep dentry cache for fast `find`/`ls`
```

## Persisting Settings

```bash
# Create a tuning file
cat > /etc/sysctl.d/99-production.conf <<'EOF'
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.min_free_kbytes = 1048576
kernel.pid_max = 4194304
fs.file-max = 2097152
EOF

# Apply immediately without reboot
sysctl -p /etc/sysctl.d/99-production.conf

# Or reload all sysctl.d files
sysctl --system
```

Files in `/etc/sysctl.d/` are loaded in lexicographic order. Higher-numbered files override lower ones. `99-custom.conf` overrides `60-postgres.conf`.

## Practical Workflow: Diagnosing Memory Issues

```bash
# Step 1: Check if you're actively swapping
grep 'pswp' /proc/vmstat

# Step 2: Check dirty page accumulation
awk '/nr_dirty|nr_writeback/' /proc/vmstat

# Step 3: Check page fault rate (major = expensive disk reads)
awk '/pgmajfault/' /proc/vmstat

# Step 4: Check current sysctl values
sysctl vm.swappiness vm.dirty_ratio vm.dirty_background_ratio vm.min_free_kbytes

# Step 5: Check memory breakdown
cat /proc/meminfo | grep -E 'MemTotal|MemFree|MemAvailable|Cached|SwapTotal|SwapFree|Dirty|Writeback'
```

## A Note on Containers

Inside a Docker container, most `sysctl -w` calls fail or have no effect — the container does not own the kernel. Sysctl values must be set:
- On the host before container start
- Via `docker run --sysctl` for per-container network sysctls
- Via Kubernetes pod `securityContext.sysctls` (requires `allowedUnsafeSysctls` in the PodSecurityPolicy/admission)

In this exercise environment, we read the current values (which are inherited from the host kernel) and practice writing scripts — actual writes may require privilege.

## Further Reading

- [kernel.org: VM sysctl documentation](https://www.kernel.org/doc/html/latest/admin-guide/sysctl/vm.html) — The authoritative reference for every `vm.*` sysctl parameter covered in this lesson (`swappiness`, `dirty_ratio`, `dirty_background_ratio`, `vfs_cache_pressure`, `min_free_kbytes`) with valid ranges and semantics.
- [kernel.org: sysctl index](https://www.kernel.org/doc/html/latest/admin-guide/sysctl/) — Complete index of all kernel sysctl namespaces (`vm`, `kernel`, `net`, `fs`) linking to per-subsystem documentation.
- [Redis memory optimization guide](https://redis.io/docs/management/admin/) — Redis's official admin guide explains why `vm.overcommit_memory=1` and `vm.swappiness=0` are required for Redis — a canonical real-world example of production VM tuning for an in-memory workload.
- [LWN: vm.swappiness — the whole story](https://lwn.net/Articles/690079/) — LWN article explaining what `vm.swappiness` actually controls in modern kernels (it is not a simple swap threshold) and why the behavior changed significantly between kernel versions.
