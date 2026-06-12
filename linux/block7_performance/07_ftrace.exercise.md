# ftrace — Exercises

> **Container note:** `/sys/kernel/debug/tracing` may require a privileged container.
> If unavailable, complete the documentation tasks and note what you observe.

Complete these tasks. Record findings in `~/practice/ftrace_notes.txt`.

## Setup

```bash
mkdir -p ~/practice
```

## Task 1 — Check debugfs availability and document the path

```bash
echo "=== ftrace filesystem check ===" >> ~/practice/ftrace_notes.txt
echo "Path: /sys/kernel/debug/tracing" >> ~/practice/ftrace_notes.txt

if [[ -d /sys/kernel/debug/tracing ]]; then
    echo "STATUS: debugfs is mounted and available" >> ~/practice/ftrace_notes.txt
    ls /sys/kernel/debug/tracing/ >> ~/practice/ftrace_notes.txt
else
    echo "STATUS: /sys/kernel/debug/tracing not available in this container" >> ~/practice/ftrace_notes.txt
    echo "To mount: mount -t debugfs debugfs /sys/kernel/debug (requires privileged container)" >> ~/practice/ftrace_notes.txt
fi
```

## Task 2 — Read available tracers (if accessible)

```bash
echo "=== available tracers ===" >> ~/practice/ftrace_notes.txt
if [[ -f /sys/kernel/debug/tracing/available_tracers ]]; then
    cat /sys/kernel/debug/tracing/available_tracers >> ~/practice/ftrace_notes.txt
else
    echo "available_tracers not readable" >> ~/practice/ftrace_notes.txt
    echo "# Expected contents: nop function function_graph blk mmiotrace" >> ~/practice/ftrace_notes.txt
fi
```

## Task 3 — List available events (if accessible)

```bash
echo "=== available event subsystems ===" >> ~/practice/ftrace_notes.txt
if [[ -d /sys/kernel/debug/tracing/events ]]; then
    ls /sys/kernel/debug/tracing/events/ >> ~/practice/ftrace_notes.txt
    echo "=== syscall tracepoints (first 10) ===" >> ~/practice/ftrace_notes.txt
    ls /sys/kernel/debug/tracing/events/syscalls/ 2>/dev/null | head -10 >> ~/practice/ftrace_notes.txt
else
    echo "events directory not accessible" >> ~/practice/ftrace_notes.txt
    echo "# Key subsystems: syscalls, sched, block, kmem, net, irq, ext4" >> ~/practice/ftrace_notes.txt
fi
```

## Task 4 — Document the ftrace enable/disable workflow

Add the canonical ftrace workflow to your notes:

```bash
cat >> ~/practice/ftrace_notes.txt << 'EOF'

=== ftrace function_graph workflow ===
# 1. Set tracer:
#    echo function_graph > /sys/kernel/debug/tracing/current_tracer
#
# 2. Filter to one function (optional):
#    echo do_sys_open > /sys/kernel/debug/tracing/set_graph_function
#
# 3. Enable tracing:
#    echo 1 > /sys/kernel/debug/tracing/tracing_on
#
# 4. Run workload, then disable:
#    echo 0 > /sys/kernel/debug/tracing/tracing_on
#
# 5. Read results:
#    cat /sys/kernel/debug/tracing/trace | head -100
#
# 6. Reset:
#    echo nop > /sys/kernel/debug/tracing/current_tracer

=== tracepoint enable workflow ===
# echo 1 > /sys/kernel/debug/tracing/events/syscalls/sys_enter_openat/enable
# cat /sys/kernel/debug/tracing/trace_pipe &   # stream events
# # run workload
# echo 0 > /sys/kernel/debug/tracing/events/syscalls/sys_enter_openat/enable
EOF
```

## Task 5 — Check trace-cmd availability

```bash
echo "=== trace-cmd availability ===" >> ~/practice/ftrace_notes.txt
which trace-cmd >> ~/practice/ftrace_notes.txt 2>&1 || echo "trace-cmd not installed (apt install trace-cmd)" >> ~/practice/ftrace_notes.txt
```

## Verification

```bash
grep "/sys/kernel/debug/tracing" ~/practice/ftrace_notes.txt
```

You should see at least one reference to the path.
