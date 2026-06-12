# Exercise: Kernel Memory

## Setup

```bash
mkdir -p ~/practice
```

## Task 1: Read and Interpret /proc/meminfo

```bash
cat /proc/meminfo
```

Answer these questions by reading the output:
- What is the total RAM? (`MemTotal`)
- How much is available for new allocations? (`MemAvailable`)
- How much page cache (file data) is in use? (`Cached`)
- Is there swap space configured? (`SwapTotal`)

Save key fields to your notes file:

```bash
grep -E "MemTotal|MemFree|MemAvailable|Cached:|SwapTotal|Dirty:" /proc/meminfo > ~/practice/memory_notes.txt
echo "Page size: $(getconf PAGE_SIZE) bytes" >> ~/practice/memory_notes.txt
cat ~/practice/memory_notes.txt
```

## Task 2: Check Page Size and Hugepages

```bash
# Standard page size
getconf PAGE_SIZE

# Hugepage info
grep -i huge /proc/meminfo

# Transparent hugepage policy
cat /sys/kernel/mm/transparent_hugepage/enabled
```

Append to notes:
```bash
echo "HugePage info:" >> ~/practice/memory_notes.txt
grep -i huge /proc/meminfo >> ~/practice/memory_notes.txt
```

## Task 3: Examine /proc/self/maps

Look at your shell's virtual address space:

```bash
cat /proc/self/maps
```

Find specific regions:

```bash
# Stack and heap
echo "=== Special regions ==="
grep -E '\[(stack|heap)\]' /proc/self/maps

# vDSO (virtual shared library in kernel space)
grep -E '\[(vdso|vvar)\]' /proc/self/maps

# Shared libraries
echo "=== Loaded libraries ==="
grep '\.so' /proc/self/maps | awk '{print $NF}' | sort -u | head -10
```

Append findings:
```bash
echo "" >> ~/practice/memory_notes.txt
echo "Memory map regions:" >> ~/practice/memory_notes.txt
grep -E '\[(stack|heap|vdso)\]' /proc/self/maps >> ~/practice/memory_notes.txt
```

## Task 4: Count Pages and Calculate Sizes

```bash
# Count total virtual memory regions for this shell
echo "Total memory regions: $(wc -l < /proc/self/maps)"

# Find total virtual address space size (sum the ranges)
# Each line: start-end permissions ...
awk '{
    split($1, a, "-")
    size = strtonum("0x"a[2]) - strtonum("0x"a[1])
    total += size
} END {printf "Total virtual space: %.1f MB\n", total/1024/1024}' /proc/self/maps
```

## Task 5: Check OOM Score

```bash
# Your shell's OOM score (0-1000)
echo "My OOM score: $(cat /proc/$$/oom_score)"
echo "My OOM adj: $(cat /proc/$$/oom_score_adj)"

# PID 1 is usually well-protected
echo "PID 1 OOM score: $(cat /proc/1/oom_score 2>/dev/null)"
echo "PID 1 OOM adj: $(cat /proc/1/oom_score_adj 2>/dev/null)"
```

Append to notes:
```bash
echo "" >> ~/practice/memory_notes.txt
echo "OOM score for $$: $(cat /proc/$$/oom_score)" >> ~/practice/memory_notes.txt
```

## Task 6: Look at Slab Cache

The slab allocator is the kernel's internal memory allocator for small objects:

```bash
# Top slab consumers
cat /proc/slabinfo 2>/dev/null | sort -k3 -rn | head -10 || \
  grep -E "Slab|SReclaimable|SUnreclaim" /proc/meminfo
```

## Expected Outcome

- `~/practice/memory_notes.txt` exists and contains "MemAvailable" (from /proc/meminfo)
- You can identify stack, heap, and vdso regions in /proc/PID/maps
- You understand the difference between MemFree and MemAvailable
