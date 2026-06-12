# File Descriptors — The Kernel's I/O Abstraction

A **file descriptor** (FD) is an integer that represents an open resource in the kernel. Files, sockets, pipes, terminals, devices, and timers are all accessed through the same FD abstraction. This uniformity is central to Unix design.

## The FD Table

Each process has a **file descriptor table** — an array of pointers to kernel `file` structs. The kernel `file` struct tracks:
- The open file description (position, flags, reference count)
- A pointer to the underlying inode (file, socket, pipe, device)

```
Process FD table        Kernel file table        Inode/vnode
  FD 0 ──────────────▶  file struct ──────────▶  /dev/pts/0
  FD 1 ──────────────▶  file struct ──────────▶  /dev/pts/0  (same inode, separate position)
  FD 2 ──────────────▶  (same file struct as FD 1 after dup2(1,2))
  FD 3 ──────────────▶  file struct ──────────▶  /etc/passwd
  FD 4 ──────────────▶  file struct ──────────▶  socket:[12345]
```

## Standard FDs

```
0  stdin   — standard input
1  stdout  — standard output
2  stderr  — standard error
```

Every process starts with these three, inherited from its parent.

## Creating FDs

| Syscall | Creates |
|---------|---------|
| `open()` | File or device FD |
| `socket()` | Socket FD |
| `pipe()` | Two FDs: read end + write end |
| `accept()` | New socket FD for incoming connection |
| `dup()` / `dup2()` | Copy of an existing FD |
| `epoll_create()` | epoll instance FD |
| `timerfd_create()` | Timer FD |
| `eventfd()` | Event notification FD |
| `signalfd()` | Signal delivery FD |

## dup and dup2 — FD Duplication

```c
int dup(int oldfd);              // lowest available FD
int dup2(int oldfd, int newfd);  // specific target FD (closes newfd first)
int dup3(int oldfd, int newfd, int flags);  // with O_CLOEXEC
```

Classic shell redirection uses `dup2`:
```bash
# Redirect stderr to stdout: dup2(1, 2)
command 2>&1

# Save and restore FDs:
exec 3>&1        # save stdout to FD 3
exec 1>/tmp/log  # redirect stdout to file
exec 1>&3        # restore stdout
exec 3>&-        # close FD 3
```

```bash
# See dup2 in action with strace
strace -e dup2 bash -c "echo hi > /tmp/test" 2>&1
```

## O_CLOEXEC — Close-on-Exec

By default, FDs are inherited by child processes across `exec()`. `O_CLOEXEC` closes the FD automatically when the process calls `execve()`:

```bash
# Check whether an FD has O_CLOEXEC set
python3 -c "import fcntl, os; print(fcntl.fcntl(3, fcntl.F_GETFD) & fcntl.FD_CLOEXEC)"

# In C: open("/path", O_RDONLY | O_CLOEXEC)
```

Why it matters: without O_CLOEXEC, forked children inherit all parent FDs — including database connections, sockets, and secrets. This causes "address already in use" bugs and security leaks.

## Inspecting FDs

```bash
# All open FDs for current shell
ls -la /proc/$$/fd

# What's behind each FD?
readlink /proc/$$/fd/0    # → /dev/pts/0
readlink /proc/$$/fd/1    # → /dev/pts/0
readlink /proc/$$/fd/255  # bash's copy of stdin for job control

# FD flags and position
cat /proc/$$/fdinfo/1     # pos, flags, mnt_id

# Count open FDs
ls /proc/$$/fd | wc -l

# FD limits
cat /proc/$$/limits | grep "Open files"
ulimit -n                 # soft limit
ulimit -Hn                # hard limit
```

## epoll — Efficient I/O Multiplexing

The modern way to watch many FDs for readability/writability without blocking:

```bash
# Watch FDs with strace to see epoll in action
strace -e epoll_create1,epoll_ctl,epoll_wait nginx 2>&1 | head -20
```

`select` and `poll` are older alternatives — both scan all FDs linearly. `epoll` uses a kernel event queue: O(1) notification regardless of how many FDs are watched.

## /dev/fd — Userspace View

```bash
ls -la /dev/fd           # symlink to /proc/self/fd
/dev/fd/0                # stdin
/dev/fd/1                # stdout

# Process substitution in bash uses /dev/fd
diff <(sort file1) <(sort file2)
# bash creates pipes, passes /dev/fd/N as filenames to diff
```

## Further Reading

- [open(2) — man7.org](https://man7.org/linux/man-pages/man2/open.2.html) — complete reference for every `O_*` flag: `O_CLOEXEC`, `O_NONBLOCK`, `O_CREAT|O_EXCL` atomicity, `O_PATH`, `O_TMPFILE`, and the interaction between flags and filesystem permissions.
- [dup2(2) — man7.org](https://man7.org/linux/man-pages/man2/dup2.2.html) — documents the atomicity guarantee that makes `dup2` safe for shell redirection, the `dup3` variant with `O_CLOEXEC`, and the race condition that `dup2` solves vs a `close`+`dup` sequence.
- [epoll(7) — man7.org](https://man7.org/linux/man-pages/man7/epoll.7.html) — explains the epoll event model, level- vs edge-triggered semantics, `EPOLLONESHOT`, the thundering herd problem addressed by `EPOLLEXCLUSIVE`, and the interaction with `fork`.
- [linux-insides — VFS](https://0xax.gitbooks.io/linux-insides/content/) — covers the kernel's virtual filesystem layer: `struct file`, `struct inode`, `struct dentry`, and how the FD table maps integer descriptors to kernel file objects.
- [Julia Evans — File descriptor tricks](https://jvns.ca/blog/2022/03/24/a-container-networking-overview/) — practical guide to FD manipulation in shell scripts: saving/restoring stdout with `exec 3>&1`, using `/dev/fd/N` with process substitution, and debugging FD leaks with `/proc/PID/fd`.
