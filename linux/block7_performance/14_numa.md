# NUMA — Non-Uniform Memory Access

In a multi-socket server, each CPU has local memory that it can access faster than memory on another CPU's socket. This topology is called **NUMA** (Non-Uniform Memory Access). Ignoring it causes unpredictable latency spikes and throughput degradation on memory-intensive workloads.

## UMA vs NUMA

**UMA (Uniform Memory Access):** All CPUs share a single memory bus. Simple, but doesn't scale beyond 2–4 sockets.

**NUMA:** Each socket has its own memory controller and local RAM. Cross-socket memory access crosses an interconnect (Intel QPI/UPI or AMD Infinity Fabric), adding 30–100 ns of latency.

```
Socket 0                    Socket 1
┌─────────────────┐         ┌─────────────────┐
│  CPU 0   CPU 1  │ ←QPI→  │  CPU 2   CPU 3  │
│   L3 Cache      │         │   L3 Cache      │
│   Local RAM     │         │   Local RAM     │
│   (fast: 60ns)  │         │   (fast: 60ns)  │
└─────────────────┘         └─────────────────┘
  ↑ cross-socket: 120-200ns ↑
```

## Discovering the NUMA Topology

```bash
# Number of NUMA nodes
ls /sys/devices/system/node/

# CPUs per node
cat /sys/devices/system/node/node0/cpulist
cat /sys/devices/system/node/node1/cpulist 2>/dev/null || echo "single NUMA node"

# Memory per node
cat /sys/devices/system/node/node0/meminfo

# numactl --hardware: the most readable summary
numactl --hardware
# available: 2 nodes (0-1)
# node 0 cpus: 0 1 2 3 4 5 6 7
# node 0 size: 32159 MB
# node 0 free: 28000 MB
# node 1 cpus: 8 9 10 11 12 13 14 15
# node 1 size: 32255 MB
# node 1 free: 29000 MB
# node distances:
# node   0   1
#   0:  10  21
#   1:  21  10

# lscpu shows NUMA topology
lscpu | grep -i numa
```

The **node distances** matrix shows the relative latency between nodes. `10` = local access; `21` = remote access (2.1× slower).

## numastat — Per-Node Memory Statistics

```bash
numastat
# numa_hit    — allocations satisfied from the requested node (good)
# numa_miss   — allocations that had to use a remote node (bad)
# numa_foreign — allocations intended for another node but landed here
# interleave_hit — interleaved allocations landing on the target node
# local_node  — pages allocated by a process running on a local CPU
# other_node  — pages allocated by a process running on a remote CPU

# Process-specific NUMA stats
numastat -p $(pgrep mysql | head -1) 2>/dev/null

# Show per-process NUMA allocation with -n
numastat -n 2>/dev/null | head -20
```

High `numa_miss` indicates processes are allocating remote memory — a performance and tuning signal.

## numactl — Running Processes with NUMA Policy

```bash
# Run a command pinned to NUMA node 0
numactl --cpunodebind=0 --membind=0 ./my_program

# Bind to node 0's CPUs, but allow memory from any node
numactl --cpunodebind=0 ./my_program

# Interleave memory across all nodes (useful for memory-intensive benchmarks)
numactl --interleave=all ./my_program

# Bind a running process to a node (Linux 4.7+)
numactl --cpunodebind=0 --membind=0 -C $(pgrep myprocess)

# taskset pins to CPUs (from block5/15); numactl pins to nodes (higher-level)
# They can be combined:
numactl --membind=0 taskset -c 0-3 ./program
```

## NUMA-Aware Process Placement

```bash
# Find which NUMA node a CPU belongs to
cat /sys/devices/system/cpu/cpu4/topology/physical_package_id

# Find all CPUs on node 0
cat /sys/devices/system/node/node0/cpulist

# Find where a process's memory is located
cat /proc/$(pgrep myapp)/numa_maps | head -20
# Format: address policy [N0=pages N1=pages] [anon=N] [file=path]
# Large N1 count on a process pinned to node 0 = remote memory allocation
```

## Practical Patterns

```bash
# Pattern 1: Database pinned to one node for consistent latency
numactl --cpunodebind=0 --membind=0 /usr/bin/mysqld --defaults-file=/etc/mysql/my.cnf

# Pattern 2: Latency-sensitive app on node 0, batch on node 1
numactl --cpunodebind=0 --membind=0 ./latency_sensitive_service &
numactl --cpunodebind=1 --membind=1 ./batch_job &

# Pattern 3: Interleave for maximum aggregate bandwidth (no locality)
numactl --interleave=all ./memory_intensive_benchmark

# Pattern 4: Memory-heavy service should avoid NUMA migrations
# Enable NUMA balancing (kernel auto-migrates memory closer to the running thread)
sysctl kernel.numa_balancing   # 1 = enabled (default)

# Disable if auto-migration causes too many TLB shootdowns
sudo sysctl -w kernel.numa_balancing=0
```

## Identifying NUMA Problems

```bash
# High remote memory accesses
numastat | awk '/numa_miss/ {if ($2+0 > 0) print "WARNING: numa_miss on node 0:", $2}'

# Process using remote memory (check numa_maps)
awk '/N1=[0-9]+/ && /N0=[0-9]+/ {
    split($0, a, " "); for (i in a) {
        if (a[i] ~ /N0=/) local+=substr(a[i],4)+0
        if (a[i] ~ /N1=/) remote+=substr(a[i],4)+0
    }
} END {
    if (remote > 0) printf "Remote pages: %d (%.1f%% of total)\n", remote, remote*100/(local+remote)
}' /proc/self/numa_maps 2>/dev/null

## Further Reading

- [numa(7) man page](https://man7.org/linux/man-pages/man7/numa.7.html) — Explains NUMA policy semantics (`bind`, `interleave`, `preferred`), the `membind`/`cpunodebind` distinction, and how kernel NUMA balancing auto-migrates pages.
- [numactl(8) man page](https://man7.org/linux/man-pages/man8/numactl.8.html) — Complete reference for every `numactl` flag (`--cpunodebind`, `--membind`, `--interleave`), the `--hardware` topology display, and how it interacts with `taskset`.
- [kernel.org: NUMA memory policy](https://www.kernel.org/doc/html/latest/admin-guide/mm/numa_memory_policy.html) — Kernel documentation for NUMA memory policies, `vm.zone_reclaim_mode`, and the `numa_maps` interface showing per-process remote page counts.
- [LWN: NUMA in a hurry](https://lwn.net/Articles/650460/) — LWN overview of NUMA topology, the cost of cross-node access, and kernel NUMA balancing (automatic page migration) — the background theory for the `numastat`/`numactl` workflow in this lesson.
