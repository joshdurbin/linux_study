# Huge Pages and Transparent Huge Pages

The CPU's Memory Management Unit (MMU) translates virtual addresses to physical addresses using page tables. With the default 4KB page size, a process using 1GB of memory requires 262,144 page table entries — and the TLB (Translation Lookaside Buffer) that caches those entries can only hold thousands. TLB misses force slow page table walks.

**Huge pages** solve this by using 2MB (or 1GB) pages, reducing TLB pressure by 512× for 2MB pages.

## Two Mechanisms

| Mechanism | Size | Configuration | How Used |
|-----------|------|--------------|---------|
| **Explicit huge pages** (HugeTLBFS) | 2MB or 1GB | Pre-allocated at boot or runtime | Application must `mmap(MAP_HUGETLB)` or use `/dev/hugepages` |
| **Transparent Huge Pages (THP)** | 2MB | Automatic | Kernel promotes 4KB pages to 2MB without application changes |

## Explicit Huge Pages

### Viewing the Current State

```bash
# From /proc/meminfo (block5/08 introduced this)
grep -i huge /proc/meminfo
# AnonHugePages:     2048 kB   ← THP in use (anonymous memory)
# ShmemHugePages:       0 kB
# HugePages_Total:     10       ← explicit hugepages allocated
# HugePages_Free:       8       ← available for use
# HugePages_Rsvd:       0       ← reserved by processes but not yet used
# HugePages_Surp:       0       ← surplus (over the pool limit)
# Hugepagesize:       2048 kB   ← size per page

# From the sysfs interface
cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
cat /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages  # 1GB pages if supported
```

### Allocating Explicit Huge Pages

```bash
# Allocate 100 huge pages (200MB) at runtime
echo 100 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages

# Verify
grep HugePages /proc/meminfo

# Allocate at boot (persistent) — add to /etc/sysctl.d/
echo "vm.nr_hugepages = 100" | sudo tee /etc/sysctl.d/99-hugepages.conf
sudo sysctl -p /etc/sysctl.d/99-hugepages.conf

# 1GB huge pages (must be set at boot via kernel parameter, not at runtime)
# hugepagesz=1G hugepages=4 in GRUB_CMDLINE_LINUX
```

### Using Explicit Huge Pages

Applications must explicitly request huge pages via `mmap(MAP_HUGETLB)` or the HugeTLBFS filesystem:

```bash
# Mount the HugeTLBFS filesystem
sudo mkdir -p /mnt/hugepages
sudo mount -t hugetlbfs hugetlbfs /mnt/hugepages -o pagesize=2M

# Applications that support huge pages automatically (database examples):
# PostgreSQL: huge_pages = on  in postgresql.conf
# MySQL:      large-pages = ON in my.cnf
# Redis:      no native support, relies on THP
# Java:       -XX:+UseLargePages -XX:LargePageSizeInBytes=2m
```

## Transparent Huge Pages (THP)

THP allows the kernel to automatically use 2MB pages for anonymous memory (heap, stack, mmap regions) without application changes. The kernel monitors 4KB page usage and promotes 512 contiguous 4KB pages to a single 2MB page when possible.

### Checking THP Configuration

```bash
# Main enable/disable switch
cat /sys/kernel/mm/transparent_hugepage/enabled
# [always] madvise never
# ^ current setting is in brackets

# always: THP is used whenever possible (aggressive)
# madvise: THP only for regions explicitly requested with madvise(MADV_HUGEPAGE)
# never: THP completely disabled

# Defragmentation behavior
cat /sys/kernel/mm/transparent_hugepage/defrag
# always: aggressively defrag memory to create 2MB regions (causes latency)
# madvise: defrag only for madvise regions
# defer: do it in background without blocking
# defer+madvise: combination
# never: no defragmentation

# khugepaged: the background daemon that does THP promotion
cat /sys/kernel/mm/transparent_hugepage/khugepaged/scan_sleep_millisecs
cat /sys/kernel/mm/transparent_hugepage/khugepaged/alloc_sleep_millisecs
```

### Tuning THP

```bash
# Disable THP entirely (recommended for latency-sensitive apps like Redis, databases)
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/defrag

# Use madvise mode (best of both worlds)
echo madvise | sudo tee /sys/kernel/mm/transparent_hugepage/enabled

# Defer defragmentation (avoids blocking latency spikes)
echo defer+madvise | sudo tee /sys/kernel/mm/transparent_hugepage/defrag

# Make permanent in /etc/rc.local or a systemd unit:
# echo never > /sys/kernel/mm/transparent_hugepage/enabled
```

### When to Disable THP

Redis, Cassandra, MongoDB, and many databases explicitly recommend disabling THP because:

1. **khugepaged compaction** causes periodic latency spikes (10ms–1s) when it merges pages
2. **Copy-on-write** (fork): duplicating a 2MB page on write is more expensive than 4KB
3. **Memory fragmentation**: THP needs contiguous 2MB regions; heavily fragmented memory falls back to 4KB anyway

```bash
# Check for THP-related latency warnings in dmesg
dmesg | grep -i "hugepage\|khugepaged\|compaction"
```

## Observing THP Usage

```bash
# THP currently in use (system-wide)
grep AnonHugePages /proc/meminfo

# Per-process THP usage
awk '/AnonHugePages/ && $2 > 0 {print FILENAME, $2 "kB"}' \
    /proc/[0-9]*/smaps 2>/dev/null | sort -t' ' -k2 -rn | head -10

# Summary: how many 2MB THP pages are in use
awk '/^AnonHugePages:/{total+=$2} END {printf "THP in use: %d MB\n", total/1024}' \
    /proc/meminfo
```

## When Huge Pages Help

| Workload | Recommendation | Reason |
|----------|---------------|--------|
| Databases (PostgreSQL, MySQL) | Explicit huge pages | Predictable allocation, no compaction stalls |
| In-memory caches (Redis, memcached) | Disable THP | Avoid compaction latency |
| Java/JVM applications | Explicit huge pages or madvise | Large heap benefits from reduced TLB misses |
| HPC/numerical computing | Explicit huge pages or `always` | Maximum throughput |
| General workloads | `madvise` (default) | THP where useful, no forced compaction |

## Further Reading

- [kernel.org: HugeTLBFS documentation](https://www.kernel.org/doc/html/latest/admin-guide/mm/hugetlbpage.html) — The authoritative guide for explicit huge pages including pool allocation, HugeTLBFS mount options, 1GB page setup, and per-NUMA-node allocation.
- [kernel.org: Transparent Hugepage Support](https://www.kernel.org/doc/html/latest/admin-guide/mm/transhuge.html) — Complete THP documentation covering `always`/`madvise`/`never` modes, `defrag` policy options, `khugepaged` tuning, and why compaction causes latency spikes in databases.
- [mmap(2) man page](https://man7.org/linux/man-pages/man2/mmap.2.html) — Documents the `MAP_HUGETLB`, `MAP_HUGE_2MB`, and `MAP_HUGE_1GB` flags for explicit huge page allocation and the `madvise(MADV_HUGEPAGE)` interface for THP opt-in.
- [Brendan Gregg: Linux huge pages](https://www.brendangregg.com/blog/2014-01-04/linux-huge-pages.html) — Practical analysis of when huge pages help vs hurt, with measurements showing the TLB miss reduction for large heap workloads and the compaction latency spike for Redis-style workloads.
