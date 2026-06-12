# bpftrace Maps

## Map Variables

Maps in bpftrace store aggregated data that persists across probe invocations. They are declared with `@`:

```bash
@name             # scalar map
@name[key]        # keyed map (hash)
@name[k1, k2]     # multi-key map
```

Maps are automatically printed when bpftrace exits (Ctrl-C or `exit()`).

## Aggregation Functions

| Function | Description |
|----------|-------------|
| `count()` | Increment a counter |
| `sum(n)` | Add n to running sum |
| `avg(n)` | Running average |
| `min(n)` | Track minimum |
| `max(n)` | Track maximum |
| `hist(n)` | Power-of-2 bucket histogram |
| `lhist(n, min, max, step)` | Linear bucket histogram |
| `stats(n)` | count, average, and total |

## Lesson 4 — Syscall Counts by Process

Count how many syscalls each process makes:

```bash
sudo bpftrace -e '
tracepoint:raw_syscalls:sys_enter {
    @[comm] = count();
}'
```

`@[comm]` creates a map keyed by process name. `count()` increments the counter for each probe fire. On exit, bpftrace prints all map entries sorted by value:

```
@[systemd]: 234
@[sshd]: 45
@[bash]: 12
```

You can key by multiple fields:

```bash
sudo bpftrace -e '
tracepoint:raw_syscalls:sys_enter {
    @[pid, comm] = count();
}'
```

## Lesson 5 — read() Byte Distribution Histogram

How many bytes does each `read()` call transfer?

```bash
sudo bpftrace -e '
tracepoint:syscalls:sys_exit_read
/args.ret > 0/ {
    @bytes = hist(args.ret);
}'
```

`args.ret` on the exit tracepoint is the return value of `read()` — the number of bytes read. The `/args.ret > 0/` filter skips errors and EOF.

Output is a power-of-2 histogram:
```
@bytes:
[1]                   23 |@@@                                 |
[2, 4)                 5 |                                    |
[4, 8)                12 |@@                                  |
[8, 16)               45 |@@@@@@@                             |
[16, 32)             120 |@@@@@@@@@@@@@@@@@@@@                |
[32, 64)              89 |@@@@@@@@@@@@@@@                     |
```

## Lesson 6 — kretprobe Latency with lhist

Measure `vfs_read` latency using a linear histogram:

```bash
sudo bpftrace -e '
kprobe:vfs_read { @start[tid] = nsecs; }
kretprobe:vfs_read /@start[tid]/ {
    @latency_us = lhist((nsecs - @start[tid]) / 1000, 0, 1000, 50);
    delete(@start[tid]);
}'
```

- `@start[tid]` saves entry timestamp keyed by thread ID
- `/@start[tid]/` filter ensures we only compute latency for reads we saw enter (avoids partial traces at startup)
- `lhist(value, min, max, step)` creates a linear histogram with 50 µs buckets from 0–1000 µs
- `delete(@start[tid])` removes the entry to avoid memory growth

## Map Printing and Clearing

```bash
# Print and clear a map from inside a probe (interval probe)
interval:s:5 {
    print(@syscalls);
    clear(@syscalls);
}
```

`print()` dumps the map immediately. `clear()` resets all entries. Useful for showing rolling windows rather than cumulative totals.

## Putting It Together — Top Syscalls with Counts

```bash
sudo bpftrace -e '
tracepoint:raw_syscalls:sys_enter { @[comm, args.id] = count(); }
END { print(@, 10); }   // print top 10
'
```

`args.id` is the syscall number. In bpftrace you can look up the name with `/usr/include/asm/unistd_64.h` or use `@[comm, probe] = count()` to get the tracepoint name directly.

## Further Reading

- [bpftrace maps documentation](https://github.com/bpftrace/bpftrace/blob/master/docs/reference_guide.md#maps) — The maps section of the bpftrace reference covering every aggregation function (`count`, `sum`, `avg`, `hist`, `lhist`, `stats`), multi-key map syntax, and the `print`/`clear` lifecycle used in this lesson.
- [kernel.org: BPF maps](https://www.kernel.org/doc/html/latest/bpf/maps.html) — Documents the underlying kernel BPF map types (`BPF_MAP_TYPE_HASH`, `BPF_MAP_TYPE_PERCPU_ARRAY`, `BPF_MAP_TYPE_RINGBUF`) that bpftrace's `@[key]` syntax abstracts, including memory limits.
- [ebpf.io: eBPF maps](https://ebpf.io/what-is-ebpf/#maps) — A clear explanation of BPF maps as the shared data layer between kernel eBPF programs and user-space, covering the map types relevant to the histogram and counter examples in this lesson.
