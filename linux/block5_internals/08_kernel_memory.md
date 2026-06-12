# Kernel Memory Management

## Virtual vs Physical Memory

Every process on Linux has its own **virtual address space** — a private, contiguous range of addresses that the process believes is its memory. The kernel (with hardware help from the MMU) maps these virtual addresses to actual physical RAM pages. This mapping is:

- **Transparent to the process**: the process doesn't know where in physical RAM its data lives
- **Flexible**: virtual pages can be swapped out to disk, shared between processes (shared libraries), or copy-on-write
- **Isolated**: processes can't access each other's physical memory

```
Process A virtual address 0x400000 → Physical page 0x12000
Process B virtual address 0x400000 → Physical page 0x87000
Shared libc  → Same physical pages mapped into both A and B
```

### Address Space Layout (64-bit x86)

A typical 64-bit Linux process sees:
- **0x400000+**: Code (text segment)
- Above text: BSS and data segments
- Above that: heap (grows upward via `brk`)
- Middle: memory-mapped files, shared libraries
- Top of user space: stack (grows downward)
- `[vsyscall]`, `[vdso]`, `[vvar]`: kernel-provided pages

```bash
# See a process's virtual address layout
cat /proc/self/maps
```

## /proc/meminfo: Understanding Memory Fields

```bash
cat /proc/meminfo
```

Key fields:

| Field | Meaning |
|-------|---------|
| `MemTotal` | Total RAM installed |
| `MemFree` | Completely unused RAM |
| `MemAvailable` | RAM available for new allocations (MemFree + reclaimable cache) — use this |
| `Buffers` | Kernel buffer cache: metadata for block devices |
| `Cached` | Page cache: recently read file data |
| `SwapCached` | Data in swap that's also in RAM |
| `Active` | Pages in active use (less likely to be reclaimed) |
| `Inactive` | Pages not recently used (candidates for reclaim) |
| `SwapTotal` | Total swap space |
| `SwapFree` | Unused swap space |
| `Dirty` | Pages modified in cache but not yet written to disk |
| `Writeback` | Pages currently being flushed to disk |
| `Slab` | Kernel data structure cache (inodes, dentries, etc.) |
| `HugePages_Total` | Huge pages allocated |

```bash
# Quick summary
awk '/MemTotal|MemAvailable|SwapTotal|SwapFree|Cached:/ {printf "%-20s %7d MB\n", $1, $2/1024}' /proc/meminfo
```

## Page Size and Hugepages

```bash
# Standard page size (almost always 4096 bytes = 4KB)
getconf PAGE_SIZE

# Hugepages: 2MB pages reduce TLB pressure for large workloads
grep HugePages /proc/meminfo

# Transparent hugepages setting
cat /sys/kernel/mm/transparent_hugepage/enabled
# Options: always, madvise [never]
```

## mmap: Memory-Mapped Files

`mmap` maps a file (or anonymous memory) directly into the process's virtual address space. Access to that region triggers page faults that the kernel resolves by loading data from disk.

**Uses of mmap**:
- Dynamic linker loads shared libraries (every process uses mmap for libc)
- Databases use mmap to access data files as if they were arrays
- Anonymous mmap is how `malloc` gets large chunks of memory from the kernel
- IPC via shared files

```bash
# Every loaded shared library appears as an mmap in /proc/PID/maps
grep '\.so' /proc/self/maps | head -5

# Anonymous mappings (no filename) are heap/stack/mmap allocations
grep ' 00:00 0 *$' /proc/self/maps
```

## /proc/PID/maps: Reading the Virtual Address Map

```bash
cat /proc/self/maps
```

Format: `address_range permissions offset dev inode pathname`

```
7f3b4c000000-7f3b4c200000 r--p 00000000 fd:00 12345  /lib/x86_64-linux-gnu/libc.so.6
7f3b4c200000-7f3b4c380000 r-xp 00200000 fd:00 12345  /lib/x86_64-linux-gnu/libc.so.6
...
7ffe12345000-7ffe12366000 rw-p 00000000 00:00 0      [stack]
7ffe123ab000-7ffe123ae000 r--p 00000000 00:00 0      [vvar]
7ffe123ae000-7ffe123b0000 r-xp 00000000 00:00 0      [vdso]
```

Permissions: `r`=read, `w`=write, `x`=execute, `p`=private (COW), `s`=shared

```bash
# Find stack, heap, vdso
grep -E '\[(stack|heap|vdso|vvar)\]' /proc/self/maps
```

## OOM Killer

When the system runs completely out of memory, the **Out-Of-Memory (OOM) killer** selects and kills a process to free memory.

```bash
# OOM score: higher = more likely to be killed (0-1000 scale)
cat /proc/$$/oom_score

# OOM score adjustment: manually bias the OOM score (-1000 to +1000)
cat /proc/$$/oom_score_adj

# Protect a process from OOM killer
echo -1000 | sudo tee /proc/$CRITICAL_PID/oom_score_adj

# Make a process more likely to be killed first
echo 500 | sudo tee /proc/$EXPENDABLE_PID/oom_score_adj

# OOM kill events appear in dmesg
dmesg | grep -i "oom\|killed process" | tail -5
```

The OOM killer score is roughly: `memory_used * adjustment_factor`. Processes with large memory footprints and high `oom_score_adj` get killed first.

## Further Reading

- [Linux kernel MM documentation — kernel.org](https://www.kernel.org/doc/html/latest/admin-guide/mm/) — kernel.org admin guide for memory management: overcommit, huge pages, memory compaction, zswap, and the OOM killer — the backing documentation for all `/proc/sys/vm/` tunables.
- [mmap(2) — man7.org](https://man7.org/linux/man-pages/man2/mmap.2.html) — complete reference for every `mmap` flag and protection combination: `MAP_PRIVATE` vs `MAP_SHARED`, `MAP_ANONYMOUS`, `MAP_HUGETLB`, `PROT_*`, and how page faults trigger on-demand allocation.
- [linux-insides — Memory Management](https://0xax.gitbooks.io/linux-insides/content/MM/) — covers the buddy allocator, slab allocator, page table structure, and how `mmap` faults are resolved through the kernel's VMA (virtual memory area) subsystem.
- [LWN — The OOM killer](https://lwn.net/Articles/391222/) — detailed analysis of the OOM killer's `oom_badness()` scoring function, `oom_score_adj`, and the memory report printed to `dmesg` before the kill.
- [madvise(2) — man7.org](https://man7.org/linux/man-pages/man2/madvise.2.html) — documents `MADV_DONTNEED`, `MADV_SEQUENTIAL`, `MADV_HUGEPAGE`, and other hints that applications use to guide kernel reclaim and prefetch decisions.
