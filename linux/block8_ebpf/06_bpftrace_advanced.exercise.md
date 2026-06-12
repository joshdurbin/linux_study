# bpftrace Advanced — Exercises

> **Container note:** bpftrace requires a privileged container. Write the script files regardless — they are the primary deliverable.

Complete these tasks. Write a bpftrace script file and notes file.

## Setup

```bash
mkdir -p ~/practice
```

## Task 1 — Write a bpftrace script file

Create `~/practice/bpftrace_advanced.bt` — a real, runnable bpftrace script:

```bash
cat > ~/practice/bpftrace_advanced.bt << 'SCRIPT'
#!/usr/bin/env bpftrace
// bpftrace_advanced.bt
// Demonstrates: struct access, block I/O, interval reporting, timed exit
// Run: sudo bpftrace ~/practice/bpftrace_advanced.bt

BEGIN {
    printf("Advanced bpftrace demo. Tracing for 15 seconds...\n");
    printf("  - file opens (vfs_open struct access)\n");
    printf("  - block I/O request sizes (block:block_rq_issue)\n");
    printf("  - context switch pairs (sched:sched_switch)\n\n");
}

// Lesson 12: struct access - get filename from vfs_open
kprobe:vfs_open {
    $path = (struct path *)arg0;
    @opens[comm, str($path->dentry->d_name.name)] = count();
}

// Lesson 11: block I/O request sizes
tracepoint:block:block_rq_issue {
    @io_bytes = hist(args.bytes);
}

// Lesson 10: scheduler context switches with kernel stack
tracepoint:sched:sched_switch {
    @switch_stacks[args.prev_comm, kstack] = count();
}

// Periodic report every 5 seconds
interval:s:5 {
    printf("\n=== File opens (top by count) ===\n");
    print(@opens, 5);

    printf("\n=== Block I/O byte distribution ===\n");
    print(@io_bytes);
}

// Auto-exit after 15 seconds
interval:s:15 {
    printf("\n=== Final context switch stacks (top 3) ===\n");
    print(@switch_stacks, 3);
    exit();
}

END {
    printf("\nTrace complete.\n");
    // suppress auto-print of large maps
    clear(@opens);
    clear(@io_bytes);
    clear(@switch_stacks);
}
SCRIPT
chmod +x ~/practice/bpftrace_advanced.bt
```

## Task 2 — Write notes explaining the script

```bash
cat > ~/practice/bpftrace_advanced_notes.txt << 'EOF'
=== bpftrace_advanced.bt — annotated ===

FILE: ~/practice/bpftrace_advanced.bt
RUN:  sudo bpftrace ~/practice/bpftrace_advanced.bt

--- Probe 1: kprobe:vfs_open with struct access ---
kprobe:vfs_open fires at the entry of the vfs_open() kernel function.
arg0 is the first argument: a struct path * containing the dentry.
The cast (struct path *)arg0 tells bpftrace the type.
$path->dentry->d_name.name traverses two struct fields to the filename.
str() converts the kernel char* pointer to a bpftrace string.
Uses $ (local variable), not @ (map variable) for the cast result.

--- Probe 2: tracepoint:block:block_rq_issue ---
Fires when a block I/O request is issued to the device driver.
args.bytes is the request size in bytes.
hist(args.bytes) creates a power-of-2 histogram of request sizes.
Helps identify random (small) vs sequential (large) I/O patterns.
args.rwbs encodes I/O type: R=read W=write S=sync D=discard F=flush.

--- Probe 3: tracepoint:sched:sched_switch ---
Fires on every CPU context switch.
args.prev_comm = process going off-CPU.
kstack = kernel call stack at the moment of switch.
Keying by [prev_comm, kstack] shows WHY each process gets descheduled.
High counts with blocking stacks = I/O or lock wait.
High counts with preempt stacks = CPU saturation.

--- interval:s:5 ---
Fires once every 5 seconds on CPU 0.
print(@map, N) prints the top N entries sorted by value.
Used here for rolling-window stats.

--- interval:s:15 + exit() ---
exit() stops bpftrace and triggers END probe.
Equivalent to pressing Ctrl-C.
Combine with interval for automated timed programs.

--- END { clear(@maps) } ---
bpftrace auto-prints all maps on exit. If you've already printed them,
use clear() in END to suppress the duplicate output.

=== Key bpftrace concepts covered ===
- Local variables: $var (action-scoped, not a map)
- Struct member access: (struct type *)ptr->field->subfield
- BTF-assisted access: works on kernels >= 5.2 with BTF enabled
- Interval probe: interval:s:N, interval:ms:N, interval:hz:N
- Timed exit: exit() from an interval probe
- Script files: runnable with "sudo bpftrace script.bt"
- Comments: // single line, /* */ block
EOF
```

## Task 3 — Verify script syntax (if bpftrace available)

```bash
if command -v bpftrace &>/dev/null; then
    echo "Checking script syntax..." >> ~/practice/bpftrace_advanced_notes.txt
    sudo bpftrace --dry-run ~/practice/bpftrace_advanced.bt 2>> ~/practice/bpftrace_advanced_notes.txt || \
        echo "Note: --dry-run may not be supported; syntax check skipped" >> ~/practice/bpftrace_advanced_notes.txt
else
    echo "bpftrace not available for syntax check" >> ~/practice/bpftrace_advanced_notes.txt
fi
```

## Verification

```bash
ls -lh ~/practice/bpftrace_advanced.bt ~/practice/bpftrace_advanced_notes.txt
```
