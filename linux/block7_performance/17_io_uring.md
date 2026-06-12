# io_uring — Modern Async I/O

`io_uring` is a Linux kernel interface (5.1+) for fully asynchronous I/O that eliminates the round-trip cost between userspace and the kernel. It's rapidly replacing `epoll` and `aio` in high-performance servers, databases, and storage engines.

## The Problem io_uring Solves

Traditional async I/O paths require **two syscalls per operation**:
1. **Submit** the I/O request
2. **Wait** for completion

Under high I/O loads, these syscalls become the bottleneck — not the disk or network.

| API | Submit syscall | Wait syscall | Limitations |
|-----|---------------|-------------|-------------|
| `read`/`write` | Implicit (blocking) | Implicit | Blocks caller |
| `aio` (POSIX AIO) | `io_submit` | `io_getevents` | Limited to O_DIRECT, no sockets |
| `epoll` | `epoll_ctl` | `epoll_wait` | Readiness-based, not completion-based |
| **io_uring** | Ring buffer write | Ring buffer read | Near-zero syscalls, all I/O types |

## The Ring Buffer Design

io_uring creates two shared-memory ring buffers between userspace and the kernel:

```
Userspace                              Kernel
┌──────────────────────────────┐
│  Submission Queue (SQ)       │  ← userspace writes requests here
│  sq[tail++] = {op, fd, buf}  │
└──────────────────────────────┘
                ↓ (kernel reads)
┌──────────────────────────────┐
│  Completion Queue (CQ)       │  ← kernel writes results here
│  cq[head++] = {res, user_data}│ ← userspace reads completions
└──────────────────────────────┘
```

The kernel monitors the SQ in a background thread (`io_uring_wq_worker`). When an operation completes, it writes the result to the CQ. Userspace reads completions without a syscall — it just reads from a shared memory region.

### SQPOLL Mode

In `SQPOLL` mode, a dedicated kernel thread polls the SQ continuously — no syscalls needed for submission or waiting:

```
io_uring_enter() → 0 syscalls in steady state (sqpoll kernel thread handles submission)
```

This is why io_uring can saturate NVMe drives at millions of IOPS with near-zero CPU overhead on syscall processing.

## Key Syscalls

```bash
# io_uring uses three syscalls (visible in strace)
io_uring_setup(entries, params)     # create the ring, returns fd
io_uring_enter(fd, to_submit, min_complete, flags)  # submit + wait
io_uring_register(fd, opcode, arg, nr_args)          # register resources

# Observe them with strace (block5/03)
strace -e trace=io_uring_setup,io_uring_enter,io_uring_register ./my_program 2>&1 | head -20
```

## Operations io_uring Supports

Unlike `aio` (file I/O only), io_uring supports:
- File I/O: `read`, `write`, `pread`, `pwrite`, `fsync`, `fdatasync`
- Socket I/O: `recv`, `send`, `accept`, `connect`
- Splice, tee, sendmsg, recvmsg
- Timeout and cancel operations
- `openat`, `close`, `statx`, `unlinkat`
- Multi-shot operations (one submission, many completions)

## Observing io_uring with strace

```bash
# Trace io_uring_setup to see ring parameters
strace -e trace=io_uring_setup ./program 2>&1

# io_uring_setup output:
# io_uring_setup(256, {flags=0, sq_thread_cpu=0, sq_thread_idle=0,
#   features=IORING_FEAT_SINGLE_MMAP|...,
#   sq_off={head=0, tail=64, ring_mask=...},
#   cq_off=...}) = 4

# Count io_uring syscalls vs total (in summary mode)
strace -c ./high_throughput_server 2>&1 | grep -E "io_uring|syscall"
```

## /proc — Inspecting io_uring FDs

When an io_uring ring is created, it's represented as a file descriptor:

```bash
# Find io_uring FDs of a running process
ls -la /proc/$(pgrep my_server)/fd/ | grep "anon_inode:\[io_uring\]"

# fdinfo shows ring state
cat /proc/$(pgrep my_server)/fdinfo/4  # where 4 is the io_uring fd
# sq_off: 0
# cq_off: ...
# sq_entries: 256
# cq_entries: 512
```

## Identifying io_uring Usage

```bash
# Does a process use io_uring? Check for the setup syscall in strace
strace -p $(pgrep myapp) -e io_uring_setup 2>&1

# Is io_uring available in this kernel?
grep -r io_uring /proc/kallsyms 2>/dev/null | head -3
# or
cat /proc/sys/kernel/io_uring_disabled 2>/dev/null
# 0 = enabled (default), 1 = disabled for unprivileged users, 2 = disabled entirely

# Which servers/tools use io_uring?
# nginx (since 1.21.4 with --with-http_v3_module)
# PostgreSQL (since 16 for WAL)
# RocksDB / TiKV storage layer
# Tokio async runtime (Rust)
# io_uring-based HTTP servers: glommio, monoio, async-std
```

## Using the io_uring Command-Line Tool

```bash
# Install io_uring utilities if available
sudo apt-get install -y liburing-dev 2>/dev/null

# The liburing library provides C API; for diagnostics:
# io-latency tool from kernel tools
perf list | grep io_uring          # io_uring tracepoints

# Trace io_uring operations with perf (from block7/05)
sudo perf trace -e io_uring:* -p $(pgrep myapp) 2>/dev/null | head -20

# Via ftrace (block7/07)
echo "io_uring:*" | sudo tee /sys/kernel/debug/tracing/set_event 2>/dev/null
cat /sys/kernel/debug/tracing/trace 2>/dev/null | head -20
```

## Kernel Configuration

```bash
# io_uring is enabled if these symbols are present
cat /proc/kallsyms 2>/dev/null | grep "io_uring_setup" | head -1

# Disable restriction (Ubuntu restricts io_uring for unprivileged users)
cat /proc/sys/kernel/io_uring_disabled 2>/dev/null
# 0 = enabled, 1 = privileged only, 2 = disabled
```

## Further Reading

- [io_uring_setup(2) man page](https://man7.org/linux/man-pages/man2/io_uring_setup.2.html) — Documents every field of the `io_uring_params` struct, the SQ/CQ ring layout, and the `IORING_FEAT_*` flags that indicate kernel capability — the low-level spec for the ring buffer design.
- [liburing GitHub and documentation](https://github.com/axboe/liburing) — The C library wrapping io_uring syscalls; includes `io_uring_queue_init`, submit/wait helpers, and examples covering all operation types listed in this lesson.
- [LWN: Ringing in a new asynchronous I/O API](https://lwn.net/Articles/776703/) — LWN's deep dive into io_uring's design, comparing it to AIO and epoll, explaining the SQPOLL mode and why two shared-memory rings eliminate the need for per-I/O syscalls.
- [Lord of the io_uring (free tutorial)](https://unixism.net/loti/) — A comprehensive free tutorial walking from basic read/write operations through advanced io_uring features like linked requests, buffer rings, and multishot accept.
- [Jens Axboe: io_uring notes](https://kernel.dk/io_uring.pdf) — The original design document by io_uring's author, explaining the motivation, the ring buffer protocol, and the SQPOLL background thread optimization.
