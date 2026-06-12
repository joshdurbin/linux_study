# bpftrace Hello World — Exercises

> **Container note:** bpftrace requires a privileged container. If unavailable, document the programs and their expected output — this is equally valuable preparation.

Complete these tasks. Record findings in `~/practice/bpftrace_hello.txt`.

## Setup

```bash
mkdir -p ~/practice
```

## Task 1 — Check bpftrace and list probes

```bash
echo "=== bpftrace availability ===" >> ~/practice/bpftrace_hello.txt
if command -v bpftrace &>/dev/null; then
    bpftrace --version >> ~/practice/bpftrace_hello.txt
    echo "--- Syscall tracepoints (first 15) ---" >> ~/practice/bpftrace_hello.txt
    sudo bpftrace -l 'tracepoint:syscalls:*' 2>/dev/null | head -15 >> ~/practice/bpftrace_hello.txt
    echo "--- Total probes available ---" >> ~/practice/bpftrace_hello.txt
    sudo bpftrace -l 2>/dev/null | wc -l >> ~/practice/bpftrace_hello.txt
else
    echo "bpftrace not installed or not accessible" >> ~/practice/bpftrace_hello.txt
fi
```

## Task 2 — Hello World probe (run or document)

```bash
echo "=== bpftrace hello world ===" >> ~/practice/bpftrace_hello.txt
if command -v bpftrace &>/dev/null; then
    echo "Running: bpftrace -e 'BEGIN { printf(\"hello world\\n\"); exit(); }'" >> ~/practice/bpftrace_hello.txt
    sudo bpftrace -e 'BEGIN { printf("hello world\n"); exit(); }' 2>/dev/null >> ~/practice/bpftrace_hello.txt
else
    cat >> ~/practice/bpftrace_hello.txt << 'EOF'
Command: sudo bpftrace -e 'BEGIN { printf("hello world\n"); exit(); }'

Expected output:
  Attaching 1 probe...
  hello world

How it works:
  - BEGIN fires once when bpftrace initializes
  - printf() works like C printf — formats and prints to stdout
  - exit() terminates the bpftrace process
  - No kernel hook is needed for BEGIN/END — they're bpftrace lifecycle probes
EOF
fi
```

## Task 3 — File opens probe (run or document)

```bash
echo "=== bpftrace file opens probe ===" >> ~/practice/bpftrace_hello.txt
if command -v bpftrace &>/dev/null; then
    echo "Running file opens probe for 3 seconds..." >> ~/practice/bpftrace_hello.txt
    sudo timeout 3 bpftrace -e \
        'tracepoint:syscalls:sys_enter_openat { printf("%s %s\n", comm, str(args.filename)); }' \
        2>/dev/null | head -20 >> ~/practice/bpftrace_hello.txt || true
else
    cat >> ~/practice/bpftrace_hello.txt << 'EOF'
Command:
  sudo bpftrace -e 'tracepoint:syscalls:sys_enter_openat {
      printf("%s %s\n", comm, str(args.filename));
  }'

Expected output:
  Attaching 1 probe...
  bash /etc/bash.bashrc
  sshd /etc/ssh/sshd_config
  systemd /proc/1/comm
  ls /etc/ld.so.cache

How it works:
  - tracepoint:syscalls:sys_enter_openat fires on every openat() syscall
  - comm is the process name (built-in)
  - args.filename is the pointer to the filename argument (from tracepoint format)
  - str() dereferences the kernel pointer and converts to a Go string

To filter to one process:
  /comm == "bash"/ { ... }
EOF
fi
```

## Task 4 — PID filter probe (document)

```bash
cat >> ~/practice/bpftrace_hello.txt << 'EOF'

=== bpftrace pid filter example ===
# Trace file opens for a specific process:
#   sudo bpftrace -e '
#   tracepoint:syscalls:sys_enter_openat
#   /pid == 1234/ {
#       printf("PID %d opened: %s\n", pid, str(args.filename));
#   }'
#
# Filter syntax: /predicate/ is evaluated before the action runs
# Built-ins available in filters: pid, tid, uid, comm, cpu, elapsed

# Trace file opens by name:
#   sudo bpftrace -e '
#   tracepoint:syscalls:sys_enter_openat
#   /comm == "nginx"/ {
#       printf("%s\n", str(args.filename));
#   }'
EOF
```

## Task 5 — Built-in variables reference

```bash
cat >> ~/practice/bpftrace_hello.txt << 'EOF'

=== bpftrace built-in variables ===
pid     - process ID
tid     - thread ID
uid     - user ID
comm    - process name (up to 16 chars)
nsecs   - current time in nanoseconds
elapsed - nanoseconds since bpftrace started
cpu     - current CPU number
kstack  - kernel stack trace (multiline string)
ustack  - user-space stack trace
args    - tracepoint arguments struct
arg0..N - kprobe positional arguments
retval  - return value (kretprobe/uretprobe only)
EOF
```

## Verification

```bash
grep -i "bpftrace" ~/practice/bpftrace_hello.txt | head -5
echo "bpftrace references found in notes"
```
