# strace Deep Dive

## What strace Does

`strace` traces **system calls** and signals for a process. Every time user-space code crosses into the kernel (reading a file, allocating memory, creating a socket), `strace` records it. This makes it invaluable for debugging "why is this program slow?" or "what files is it touching?" — without needing source code.

Overhead is significant (5–50x slowdown) because `strace` uses `ptrace(2)` to stop and inspect the process at each syscall. Never use it on latency-sensitive production processes without understanding the impact.

## Running strace

**Trace a new command:**
```bash
strace ls /tmp
```

**Attach to a running process:**
```bash
strace -p 1234
```

**Follow forked children:**
```bash
strace -f bash -c 'ls && echo done'
```

## Key Flags

| Flag | Effect |
|------|--------|
| `-c` | Summary: count calls, time spent, errors per syscall |
| `-e trace=openat,read,write` | Filter to specific syscalls |
| `-e trace=file` | All file-related syscalls |
| `-e trace=network` | All network syscalls |
| `-T` | Show time spent in each syscall |
| `-tt` | Absolute timestamps (HH:MM:SS.usec) |
| `-s 256` | Max string length to print (default 32) |
| `-o /tmp/out.txt` | Write trace to file instead of stderr |
| `-f` | Follow forks (trace child processes too) |
| `-ff -o /tmp/trace` | Follow forks, one file per PID |

## Reading strace Output

```
openat(AT_FDCWD, "/etc/ld.so.cache", O_RDONLY|O_CLOEXEC) = 3
read(3, "\177ELF\2\1\1\0\0\0\0\0\0\0\0\0"..., 832) = 832
close(3)                                = 0
```

Format: `syscall(args) = return_value`

- Return value `-1` with `errno` in the trace = error: `openat(...) = -1 ENOENT (No such file or directory)`
- Common errors: `ENOENT` (file not found), `EACCES` (permission denied), `EAGAIN` (would block, try again)

## Summary Mode: -c

```bash
strace -c ls /tmp
```

Output shows total time, calls, and errors per syscall — useful for finding which syscall category consumes the most time without reading thousands of lines.

## Common Diagnostic Patterns

**What files does this program open?**
```bash
strace -e openat -s 256 nginx -t 2>&1 | grep -v ENOENT
```

**Why is startup slow?**
```bash
strace -T -tt -o /tmp/slow.trace ./myapp
grep -E '[0-9]{3,}\.' /tmp/slow.trace   # calls taking >100ms
```

**What network connections does it make?**
```bash
strace -e trace=network -f curl https://example.com 2>&1 | grep -E 'connect|send|recv'
```

**Find missing config files:**
```bash
strace -e openat 2>&1 myapp | grep ENOENT
```

## Signals in strace Output

Signals appear as:
```
--- SIGTERM {si_signo=SIGTERM, si_code=SI_USER, si_pid=1234} ---
```

And handler execution as:
```
+++ killed by SIGKILL +++
```

## Alternatives When strace is Too Expensive

- **ltrace**: traces library calls instead of syscalls (lower kernel overhead)
- **perf trace**: uses tracepoints instead of ptrace — much lower overhead
- **bpftrace/BCC opensnoop**: eBPF-based, negligible overhead

## Further Reading

- [strace(1) man page](https://man7.org/linux/man-pages/man1/strace.1.html) — The authoritative reference for every strace flag (`-c`, `-T`, `-tt`, `-e trace=`, `-f`, `-ff`) and output format field documented in this lesson's flag table.
- [ptrace(2) man page](https://man7.org/linux/man-pages/man2/ptrace.2.html) — Documents the kernel ptrace mechanism that strace uses internally, explaining the stop-inspect-resume cycle that causes the 5–50× overhead.
- [Julia Evans: Why strace doesn't work in Docker](https://jvns.ca/blog/2020/04/29/why-strace-doesnt-work-in-docker/) — Explains the capability and seccomp restrictions that prevent strace from working in standard containers and how to work around them.
- [Brendan Gregg: strace wow much syscall](https://www.brendangregg.com/blog/2014-05-11/strace-wow-much-syscall.html) — Quantifies strace overhead with measurements and explains why BCC/eBPF alternatives like `opensnoop` are preferred in production.
