# bpftrace Advanced — Struct Access, Block I/O, and Script Files

## Lesson 10 — Scheduler Tracing with Stacks

Track which kernel code paths cause context switches:

```bash
sudo bpftrace -e '
tracepoint:sched:sched_switch {
    @[args.prev_comm, kstack] = count();
}'
```

Combining `prev_comm` (the process going off-CPU) with `kstack` (the kernel stack at switch time) reveals why each process got descheduled — whether it voluntarily blocked on I/O, a mutex, or was preempted.

## Lesson 11 — Block I/O Analysis

Measure the distribution of I/O request sizes at the block layer:

```bash
sudo bpftrace -e '
tracepoint:block:block_rq_issue {
    @bytes = hist(args.bytes);
}'
```

`block_rq_issue` fires when an I/O request is dispatched to the device driver. `args.bytes` is the request size. The histogram reveals whether workloads are using small random I/Os (bad for HDDs) or large sequential I/Os.

Extended version with per-device breakdown:

```bash
sudo bpftrace -e '
tracepoint:block:block_rq_issue {
    @[args.rwbs, args.dev] = hist(args.bytes);
}'
```

`args.rwbs` is a string encoding the I/O type: "R" = read, "W" = write, "S" = sync, "M" = metadata, "D" = discard.

## Lesson 12 — Struct Access

bpftrace can dereference kernel data structures. To get the filename from `vfs_open`:

```bash
sudo bpftrace -e '
kprobe:vfs_open {
    printf("%s\n", str(((struct path *)arg0)->dentry->d_name.name));
}'
```

`arg0` is the first argument to `vfs_open`, which is a `struct path *`. The cast `(struct path *)arg0` tells bpftrace the type. Then `->dentry->d_name.name` navigates the struct fields to the filename.

With BTF (kernel 5.2+), bpftrace can access struct members without manual type casts:

```bash
sudo bpftrace -e '
kprobe:vfs_open {
    $path = (struct path *)arg0;
    printf("%s\n", str($path->dentry->d_name.name));
}'
```

Local variables use `$` (not `@`), are not maps, and are scoped to the probe action.

## Interval Probes for Periodic Reporting

```bash
sudo bpftrace -e '
tracepoint:syscalls:sys_enter_read { @[comm] = count(); }
interval:s:5 {
    print(@);
    clear(@);
}
END { clear(@); }
'
```

`interval:s:5` fires once every 5 seconds on CPU 0. Use it to reset and reprint maps for rolling-window statistics. `END { clear(@); }` suppresses the automatic map print on exit (since you've already printed and cleared).

## Timed Programs with exit()

```bash
sudo bpftrace -e '
BEGIN { printf("Tracing for 10 seconds...\n"); }
tracepoint:syscalls:sys_enter_write { @[comm] = count(); }
interval:s:10 { exit(); }
'
```

`exit()` causes bpftrace to stop and print maps, equivalent to pressing Ctrl-C. Combine with `interval` for timed programs that don't need the user to manually interrupt.

## Writing bpftrace Scripts to Files

For complex programs, use `.bt` script files instead of inline `-e`:

```bash
# /home/student/practice/watch_opens.bt
BEGIN {
    printf("Watching file opens. Ctrl-C to stop.\n");
}

tracepoint:syscalls:sys_enter_openat {
    @opens[comm] = count();
}

tracepoint:syscalls:sys_exit_openat
/args.ret < 0/ {
    @errors[comm, args.ret] = count();
}

interval:s:10 {
    print(@opens);
    print(@errors);
    clear(@opens);
    clear(@errors);
}
```

Run with:
```bash
sudo bpftrace watch_opens.bt
```

Script files support comments (`//`), all the same probes and functions, and are easier to maintain than long one-liners.

## Type Casting Reference

| Cast | Example |
|------|---------|
| Pointer cast | `(struct sk_buff *)arg0` |
| Integer cast | `(uint64)arg0` |
| Local variable | `$var = expr` |
| Map variable | `@map[key] = expr` |
| String from pointer | `str(ptr)` |
| String with length | `str(ptr, len)` |

## Further Reading

- [bpftrace tools directory](https://github.com/bpftrace/bpftrace/tree/master/tools) — Production-ready `.bt` scripts (`biolatency.bt`, `tcplife.bt`, `opensnoop.bt`) demonstrating struct access, interval probes, and script file patterns from this lesson in real-world tracing contexts.
- [CO-RE BPF reference guide](https://nakryiko.com/posts/bpf-core-reference-guide/) — Andrii Nakryiko's (libbpf maintainer) deep dive into CO-RE relocation, BTF-based struct access, and how `__attribute__((preserve_access_index))` enables the portable struct navigation shown in Lesson 12.
- [bpf-developer-tutorial](https://eunomia.dev/tutorials/) — A structured progression from basic eBPF programs through CO-RE, libbpf, and advanced topics like interval probes and timed programs — builds on the patterns introduced in this lesson.
