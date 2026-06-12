# System Calls

## The Kernel/Userspace Boundary

Every program runs in **userspace** — a protected memory region that cannot directly touch hardware or kernel data structures. When a program needs to do anything privileged (read a file, allocate memory, create a process, send a network packet), it must ask the kernel via a **system call** (syscall).

A syscall is a controlled transfer from userspace into kernel mode. The CPU switches privilege level, executes the kernel function, and returns control (and a result) to userspace.

```
[userspace] open("file.txt", O_RDONLY)
               ↓ syscall instruction
[kernel mode] sys_openat() — validates path, checks permissions, returns fd
               ↓ return
[userspace] receives file descriptor (e.g., 3)
```

## How Syscalls Work: Mechanics

- **x86-64 Linux**: Uses the `syscall` instruction. The syscall number goes in `rax`, arguments in `rdi`, `rsi`, `rdx`, `r10`, `r8`, `r9`.
- **Legacy 32-bit**: Used `int 0x80` software interrupt.
- **vDSO** (virtual Dynamic Shared Object): For high-frequency, read-only calls like `gettimeofday()` and `clock_gettime()`, the kernel maps a small shared library into every process. These run entirely in userspace — no actual kernel transition — making them extremely fast.

```bash
# See vDSO in a process's memory map
grep vdso /proc/self/maps
```

## Important Syscalls to Know

### File Operations
| Syscall | Purpose |
|---------|---------|
| `open` / `openat` | Open a file, return a file descriptor |
| `read` | Read bytes from an fd |
| `write` | Write bytes to an fd |
| `close` | Release a file descriptor |
| `stat` / `fstat` | Get file metadata |
| `lseek` | Move read/write position |

### Process Management
| Syscall | Purpose |
|---------|---------|
| `fork` | Create a copy of the current process |
| `exec` / `execve` | Replace the current process with a new program |
| `wait` / `waitpid` | Wait for a child process to finish |
| `exit` | Terminate the current process |
| `clone` | Like fork but with fine-grained control (used by threads, containers) |

### Memory Management
| Syscall | Purpose |
|---------|---------|
| `mmap` | Map files or anonymous memory into the address space |
| `munmap` | Unmap a memory region |
| `brk` / `sbrk` | Adjust the heap boundary (used by `malloc`) |
| `mprotect` | Change memory region permissions |

## strace: Tracing System Calls

`strace` attaches to a process and prints every syscall it makes. Invaluable for debugging.

### Basic Usage

```bash
# Trace all syscalls of a command
strace ls

# Trace with summary count and time
strace -c ls

# Filter to specific syscalls
strace -e trace=open,read,write ls

# Attach to a running process
strace -p <PID>

# Follow child processes (forks)
strace -f ls

# Save output to file
strace -o /tmp/trace.txt ls
```

### Interpreting strace Output

```
openat(AT_FDCWD, "/etc/ld.so.cache", O_RDONLY|O_CLOEXEC) = 3
read(3, "\177ELF\2\1\1\0\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0"..., 832) = 832
close(3)                                = 0
```

Each line: `syscall_name(arguments) = return_value`
- Return `>= 0`: success (often an fd or byte count)
- Return `-1`: error (followed by `errno` name, e.g., `ENOENT`)

### strace -c: Summary Mode

```bash
strace -c ls /tmp
# % time     seconds  usecs/call     calls    errors syscall
# ------ ----------- ----------- --------- --------- ----------------
#  34.21    0.000132          11        12           mmap
#  18.13    0.000070           8         9           read
#  ...
```

### Useful Filters

```bash
# Only file-related calls
strace -e trace=file ls

# Only process-related calls
strace -e trace=process bash -c 'echo hi'

# Only network calls
strace -e trace=network curl -s http://localhost
```

## /proc/PID/syscall

See what syscall a process is currently executing:

```bash
cat /proc/$$/syscall
# 270 0x7f3... 0x1000 ... <hex args>  <instruction pointer>  <stack pointer>
# The first number is the syscall number
```

Look up syscall numbers in `/usr/include/asm/unistd_64.h` or online.

## Why Syscalls Matter for SREs

- **Performance**: Too many syscalls can be a bottleneck. `strace -c` helps identify excessive calls.
- **Security**: seccomp filters restrict which syscalls a process can make (used by Docker, browsers).
- **Debugging**: A hung process? `strace -p PID` shows exactly what it's waiting on.
- **Understanding tools**: `strace ls` demystifies what "simple" commands actually do.

## Further Reading

- [syscall(2) — man7.org](https://man7.org/linux/man-pages/man2/syscall.2.html) — authoritative reference for syscall calling conventions on every architecture: which registers hold the syscall number and arguments, and how errno is returned.
- [syscalls(2) — man7.org](https://man7.org/linux/man-pages/man2/syscalls.2.html) — the complete list of every Linux syscall with a one-line description, kernel version when introduced, and links to individual man pages.
- [linux-insides — System Calls chapter](https://0xax.gitbooks.io/linux-insides/content/SysCall/) — detailed walkthrough of the `syscall` instruction entry path: MSR setup, `entry_SYSCALL_64`, the syscall table, and return to userspace.
- [LWN — Anatomy of a system call](https://lwn.net/Articles/604287/) — LWN two-part series tracing a syscall from userspace through the vDSO, the `syscall` instruction, kernel-side dispatch, and back including the `SYSENTER` legacy path.
- [Julia Evans — strace zine](https://jvns.ca/blog/2015/04/14/strace-zine/) — accessible introduction to system call tracing with `strace`, covering the most common syscalls and how to interpret `strace` output for debugging real programs.
