# Exercise: io_uring

## Setup

```bash
mkdir -p ~/practice/io_uring
```

## Task 1: Check io_uring Kernel Support

```bash
echo "=== io_uring Availability ==="

# Check if io_uring syscalls are in kallsyms
grep -c "io_uring" /proc/kallsyms 2>/dev/null && echo "io_uring symbols found in kernel" || \
    echo "kallsyms check: N/A"

# Check io_uring disabled setting (Ubuntu security restriction)
if [ -f /proc/sys/kernel/io_uring_disabled ]; then
    VAL=$(cat /proc/sys/kernel/io_uring_disabled)
    case $VAL in
        0) echo "io_uring: enabled (all users)" ;;
        1) echo "io_uring: restricted to privileged users" ;;
        2) echo "io_uring: disabled entirely" ;;
    esac
else
    echo "io_uring_disabled sysctl not present (kernel may not have this knob)"
fi

# Kernel version (io_uring requires 5.1+)
uname -r
```

## Task 2: Identify Applications Using io_uring

```bash
echo "=== Processes Using io_uring ==="

# Look for io_uring FDs in running processes
for pid in /proc/[0-9]*/fd; do
    proc=$(dirname $pid)
    pid_num=$(basename $proc)
    comm=$(cat $proc/comm 2>/dev/null)
    if ls -la $pid 2>/dev/null | grep -q "io_uring"; then
        echo "PID $pid_num ($comm) has io_uring FD"
    fi
done | head -20

echo "(empty means no processes using io_uring right now)"
```

## Task 3: Trace io_uring Syscalls with strace

```bash
# Trace all io_uring-related syscalls for a command
# Most regular commands don't use io_uring, so this shows the absence
echo "Tracing syscalls for ls:"
strace -e trace=io_uring_setup,io_uring_enter,io_uring_register ls /tmp 2>&1 | \
    grep -E "io_uring|syscall" || echo "ls uses no io_uring syscalls (expected)"

# Syscall summary to see io_uring presence
strace -c ls /tmp 2>&1 | grep -E "io_uring|syscalls"
```

## Task 4: Find io_uring Tracepoints

```bash
echo "=== io_uring Tracepoints ==="

# List available io_uring tracepoints via perf (from block7/05)
perf list 2>/dev/null | grep io_uring | head -20 || echo "perf not available or no io_uring tracepoints"

# Or from the ftrace system (block7/07)
ls /sys/kernel/debug/tracing/events/io_uring/ 2>/dev/null | head -20 || \
    echo "io_uring tracepoints not available (normal in containers)"
```

## Task 5: Read io_uring fdinfo for a Running Process

```bash
# Find any process with io_uring FDs
TARGET_PID=""
for pid in $(ls /proc | grep -E '^[0-9]+$' | head -50); do
    if ls /proc/$pid/fd 2>/dev/null | xargs -I{} readlink /proc/$pid/fd/{} 2>/dev/null | \
            grep -q "io_uring"; then
        TARGET_PID=$pid
        break
    fi
done

if [ -n "$TARGET_PID" ]; then
    echo "Found io_uring in PID $TARGET_PID ($(cat /proc/$TARGET_PID/comm 2>/dev/null))"
    for fd in /proc/$TARGET_PID/fd/*; do
        link=$(readlink $fd 2>/dev/null)
        if echo "$link" | grep -q io_uring; then
            fd_num=$(basename $fd)
            echo "io_uring FD $fd_num fdinfo:"
            cat /proc/$TARGET_PID/fdinfo/$fd_num 2>/dev/null
        fi
    done
else
    echo "No processes currently using io_uring found"
    echo "Try running nginx or another io_uring-enabled server"
fi
```

## Task 6: Write an io_uring Presence Check Script

```bash
cat > ~/practice/io_uring/check_io_uring.sh << 'EOF'
#!/bin/bash
echo "=== io_uring System Check ==="

# Kernel version
echo "Kernel: $(uname -r)"

# io_uring disabled setting
if [ -f /proc/sys/kernel/io_uring_disabled ]; then
    VAL=$(cat /proc/sys/kernel/io_uring_disabled)
    case $VAL in
        0) STATUS="enabled" ;;
        1) STATUS="privileged only" ;;
        2) STATUS="disabled" ;;
        *) STATUS="unknown ($VAL)" ;;
    esac
    echo "io_uring_disabled: $VAL ($STATUS)"
fi

# Count io_uring users
URING_USERS=0
for pid in $(ls /proc | grep -E '^[0-9]+$' 2>/dev/null); do
    ls /proc/$pid/fd 2>/dev/null | \
        xargs -I{} readlink "/proc/$pid/fd/{}" 2>/dev/null | \
        grep -q "io_uring" && URING_USERS=$((URING_USERS + 1))
done
echo "Processes using io_uring: $URING_USERS"

# Tracepoints available?
if ls /sys/kernel/debug/tracing/events/io_uring/ > /dev/null 2>&1; then
    COUNT=$(ls /sys/kernel/debug/tracing/events/io_uring/ | wc -l)
    echo "io_uring tracepoints: $COUNT available"
else
    echo "io_uring tracepoints: not accessible"
fi
EOF
chmod +x ~/practice/io_uring/check_io_uring.sh
bash ~/practice/io_uring/check_io_uring.sh
```

## Expected Outcome

- Kernel version is >= 5.1 (io_uring availability)
- `io_uring_disabled` sysctl is readable (0, 1, or 2)
- `strace -e trace=io_uring_*` runs without error on any command
- io_uring tracepoints are listed via `perf list` or `/sys/kernel/debug/tracing/events/io_uring/`
- `~/practice/io_uring/check_io_uring.sh` reports io_uring system status
