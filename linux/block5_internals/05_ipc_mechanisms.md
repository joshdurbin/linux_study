# IPC Mechanisms

## What is IPC?

**Inter-Process Communication (IPC)** is how processes exchange data and coordinate. Linux provides several mechanisms, each with different trade-offs in speed, persistence, and complexity.

## Pipes

### Unnamed Pipes (|)

The shell pipe operator creates an **unnamed pipe** in the kernel — a one-directional, in-memory buffer connecting two processes. The pipe exists only while both processes are alive.

```bash
# Classic pipe: stdout of ls → stdin of grep
ls /etc | grep conf

# Multi-stage pipeline
cat /var/log/syslog | grep ERROR | sort | uniq -c | sort -rn | head

# Check pipe buffer size
cat /proc/sys/fs/pipe-max-size
# 1048576 (1MB, the maximum a single pipe can be enlarged to)
# Default pipe buffer is 65536 bytes (64KB)
```

Key properties:
- One-directional (write one end, read the other)
- **Blocking**: writer blocks when buffer is full, reader blocks when empty
- Data is a byte stream (no message boundaries)

### Named Pipes (FIFOs)

A **named pipe** (FIFO) is a pipe with a name in the filesystem. Unlike unnamed pipes, it persists on disk and can be opened by unrelated processes.

```bash
# Create a named pipe
mkfifo ~/practice/myfifo

# Check its type (p = pipe)
ls -la ~/practice/myfifo
# prw-r--r-- 1 student student 0 Jun  1 10:00 /home/student/practice/myfifo

# In terminal 1: write to the pipe (blocks until reader opens it)
echo "hello from writer" > ~/practice/myfifo

# In terminal 2: read from the pipe
cat ~/practice/myfifo

# Using a fifo for a log monitor
tail -f /var/log/syslog > ~/practice/myfifo &
grep --line-buffered "error" < ~/practice/myfifo

# Clean up
rm ~/practice/myfifo
```

Test for a named pipe in scripts:
```bash
if [ -p /path/to/file ]; then
    echo "It's a named pipe"
fi
```

## Shared Memory

Shared memory is the **fastest IPC mechanism** — processes map the same physical memory pages into their address space and read/write directly, with no kernel copy.

### /dev/shm — Shared Memory Filesystem

`/dev/shm` is a tmpfs mount for shared memory. Any process can create files here as RAM-backed storage:

```bash
# Write to shared memory
echo "shared data" > /dev/shm/mydata.txt

# Read from another process (or shell)
cat /dev/shm/mydata.txt

# Check /dev/shm size limit
df -h /dev/shm

# Use it for IPC via a temp file (fast, stays in RAM)
python3 -c "open('/dev/shm/ipc', 'w').write('ping')"
cat /dev/shm/ipc

# Clean up (important — /dev/shm is limited RAM)
rm /dev/shm/mydata.txt /dev/shm/ipc
```

### System V Shared Memory (ipcs)

The classic POSIX/SysV IPC includes shared memory segments, message queues, and semaphores. Inspect them with `ipcs`:

```bash
# List all SysV IPC objects
ipcs

# List shared memory segments only
ipcs -m

# List message queues
ipcs -q

# List semaphores
ipcs -s

# Remove a shared memory segment by ID
ipcrm -m <shmid>

# Remove all SysV shared memory owned by current user
ipcs -m | grep $USER | awk '{print $2}' | xargs -r ipcrm -m
```

## Unix Domain Sockets

Unix domain sockets (UDS) are like network sockets but within a single host — communication happens through the filesystem, not the network stack. They're faster than TCP loopback and support credential passing.

```bash
# Common Unix sockets on a system
ls -la /var/run/*.sock 2>/dev/null
ls -la /tmp/.s.PGSQL* 2>/dev/null  # PostgreSQL
ls -la /run/docker.sock 2>/dev/null  # Docker daemon

# Check Unix sockets with ss
ss -xl  # list Unix domain sockets in LISTEN state
ss -xp  # show process names

# Test a Unix socket with socat
socat - UNIX-CONNECT:/var/run/docker.sock  # if you have access
```

UDS vs TCP for local IPC:
- **UDS**: No IP stack overhead, faster, supports `SO_PEERCRED` (verify caller's UID/GID)
- **TCP loopback**: Works across machines, easier to proxy, slightly more overhead

## Message Queues (Brief)

SysV message queues allow processes to send discrete messages with a type field, enabling selective receive:

```bash
# This requires C programming or Python bindings for real use
# Check if any queues exist
ipcs -q
```

POSIX message queues (`mq_open`) are the modern alternative, mounted at `/dev/mqueue`:

```bash
ls /dev/mqueue/
```

## Semaphores (Brief)

Semaphores coordinate access to shared resources (mutex-style):

```bash
# Check existing semaphores
ipcs -s

# Named POSIX semaphores appear in
ls /dev/shm/sem.*
```

## Pipe Buffer Tuning

```bash
# Maximum size a pipe can be enlarged to (bytes)
cat /proc/sys/fs/pipe-max-size

# Default size allocated to each new pipe
cat /proc/sys/fs/pipe-user-pages-soft
```

Programs using `fcntl(fd, F_SETPIPE_SZ, size)` can enlarge their pipe buffer up to `pipe-max-size` to improve throughput for large data transfers.

## Further Reading

- [pipe(2) — man7.org](https://man7.org/linux/man-pages/man2/pipe.2.html) — covers pipe creation, the 64KB default buffer capacity, `O_DIRECT` message-mode semantics for POSIX pipes, and `F_SETPIPE_SZ` for enlarging pipe buffers up to `pipe-max-size`.
- [unix(7) — man7.org](https://man7.org/linux/man-pages/man7/unix.7.html) — documents Unix domain socket semantics: `SOCK_STREAM` vs `SOCK_DGRAM` vs `SOCK_SEQPACKET`, the abstract namespace, `SO_PEERCRED` for credential passing, and autobind.
- [mq_overview(7) — man7.org](https://man7.org/linux/man-pages/man7/mq_overview.7.html) — full overview of POSIX message queues: the `/dev/mqueue` filesystem, `mq_open`/`mq_send`/`mq_receive` API, priority-based receive, and `mq_notify` for async notification.
- [LWN — Dude, where's my data? IPC mechanisms](https://lwn.net/Articles/486391/) — survey of Linux IPC mechanisms comparing pipes, shared memory, sockets, and message queues with performance benchmarks and guidance on which to choose for different communication patterns.
