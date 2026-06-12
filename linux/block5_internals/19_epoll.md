# epoll — Event-Driven I/O

epoll is the Linux kernel's mechanism for monitoring thousands of file descriptors efficiently. It's the foundation of every high-performance Linux server: nginx, Redis, Node.js, PostgreSQL, and the kernel's own io_uring all use it.

## The Problem: Blocking and Polling

A naive server accepts connections and blocks on `read()` for each one. To handle multiple clients, it spawns a thread per client — expensive at scale.

**select(2)** and **poll(2)** allow monitoring multiple FDs, but they require passing the full FD set to the kernel on every call and scanning the entire set to find ready FDs. Cost: O(n) per call.

**epoll(2)** maintains the FD set inside the kernel. The call to wait returns only the ready FDs. Cost: O(1) wait + O(ready) result processing.

## The epoll API

Three syscalls:

```c
// Create an epoll instance
int epfd = epoll_create1(EPOLL_CLOEXEC);

// Register a file descriptor to watch
struct epoll_event ev = {
    .events = EPOLLIN | EPOLLET,  // watch for readable, edge-triggered
    .data.fd = client_fd,
};
epoll_ctl(epfd, EPOLL_CTL_ADD, client_fd, &ev);

// Wait for events (blocks until at least one FD is ready)
struct epoll_event events[MAX_EVENTS];
int n = epoll_wait(epfd, events, MAX_EVENTS, timeout_ms);
for (int i = 0; i < n; i++) {
    // events[i].data.fd is ready
}
```

```bash
# See epoll syscalls via strace (block5/03)
strace -e trace=epoll_create1,epoll_ctl,epoll_wait nginx 2>&1 | head -20

# nginx creates epoll instances at startup
strace -p $(pgrep nginx | head -1) -e epoll_wait 2>&1 | head -5
```

## Level-Triggered vs Edge-Triggered

This is the most important concept in epoll usage.

### Level-Triggered (LT) — the default

epoll notifies you **as long as** there is data to read. If you don't read all available data, the next `epoll_wait` call returns immediately again.

```
Data arrives:    [100 bytes in buffer]
epoll_wait:      → returns ready (100 bytes available)
read(50 bytes):  [50 bytes remaining]
epoll_wait:      → returns ready again (50 bytes still available)
read(50 bytes):  [0 bytes remaining]
epoll_wait:      → blocks (buffer empty)
```

Safe: works correctly even if you read less than the available data.

### Edge-Triggered (ET) — `EPOLLET` flag

epoll notifies you **only when** the state changes (from not-ready to ready). You get exactly one notification per data arrival.

```
Data arrives:    [100 bytes in buffer]
epoll_wait:      → returns ready (state changed)
read(50 bytes):  [50 bytes remaining]
epoll_wait:      → BLOCKS (no state change — but data is still there!)
read(50 bytes):  [0 bytes remaining]
... more data arrives ...
epoll_wait:      → returns ready (state changed again)
```

**Edge-triggered requirement**: you MUST drain the FD completely in a loop until `read()` returns `EAGAIN`. Otherwise you'll miss data.

```c
// ET requires non-blocking I/O + drain loop
fcntl(fd, F_SETFL, O_NONBLOCK);
ev.events = EPOLLIN | EPOLLET;

// On notification:
while (true) {
    ssize_t n = read(fd, buf, sizeof(buf));
    if (n < 0) {
        if (errno == EAGAIN || errno == EWOULDBLOCK) break;  // drained
        // real error
    }
    if (n == 0) break;  // EOF
    process(buf, n);
}
```

ET is more efficient (fewer syscalls) but harder to implement correctly.

## Non-Blocking I/O

epoll is almost always used with non-blocking sockets:

```bash
# Set a FD to non-blocking mode
fcntl(fd, F_SETFL, O_NONBLOCK)

# Or at socket creation:
socket(AF_INET, SOCK_STREAM | SOCK_NONBLOCK, 0)

# Observe non-blocking flag on a process's FDs
cat /proc/$(pgrep nginx | head -1)/fdinfo/5   # shows flags field
# flags: 0100002 → O_RDWR | O_NONBLOCK (bit 11 = O_NONBLOCK = 0o04000 = 2048)
```

## epoll Events

| Event | Meaning |
|-------|---------|
| `EPOLLIN` | Data available to read |
| `EPOLLOUT` | Write buffer has space (socket is writable) |
| `EPOLLRDHUP` | Peer closed connection (or half-close) |
| `EPOLLHUP` | Hang-up — connection broken (always monitored, no need to set) |
| `EPOLLERR` | Error on FD (always monitored) |
| `EPOLLET` | Edge-triggered mode |
| `EPOLLONESHOT` | Only deliver one event, then auto-deregister |
| `EPOLLEXCLUSIVE` | Avoid thundering herd — deliver to only one waiting thread |

## Observing epoll in Production

```bash
# How many FDs does nginx have open?
ls /proc/$(pgrep nginx | head -1)/fd | wc -l

# What epoll instances does nginx use?
ls -la /proc/$(pgrep nginx | head -1)/fd | grep "eventpoll"
# Each epoll instance appears as an anon_inode:[eventpoll]

# fdinfo shows what's registered in an epoll instance
cat /proc/$(pgrep nginx | head -1)/fdinfo/4   # where 4 is the epoll FD
# tfd: 10 events: 1d data: 0000000a00000000
# tfd = target FD being watched
# events = bitmask (EPOLLIN|EPOLLET etc.)

# How many connections is nginx handling?
ss -s | grep "estab"

# Correlate with epoll: each established connection is one entry in epoll
```

## The Event Loop Pattern

epoll enables a **single-threaded event loop** to handle thousands of connections:

```
while running:
    events = epoll_wait(epfd, ...)    # block until something is ready
    for each event:
        if event.fd == listen_fd:
            accept()                   # new connection
            epoll_ctl(ADD, new_fd)     # register with epoll
        elif event is readable:
            read() → process → write() # handle existing connection
        elif event is writable:
            flush_send_buffer()
        elif event is closed:
            epoll_ctl(DEL, fd)         # unregister
            close(fd)
```

Redis, nginx, and Node.js all follow this pattern. One thread, millions of connections.

## When epoll vs Threads

| Approach | Best For | Scaling Limit |
|----------|---------|--------------|
| Thread per connection | CPU-bound or blocking I/O | ~10k threads (memory) |
| epoll event loop | I/O-bound, many idle connections | millions of FDs |
| epoll + thread pool | Mixed: epoll dispatches, threads compute | CPU core count |

## Performance Comparison

```bash
# select: O(n) — scans ALL watched FDs on every call
# poll: O(n) — same, but no FD_SETSIZE limit
# epoll: O(1) — only returns ready FDs

# At 10,000 connections:
# select: 10,000 FD checks per epoll_wait call
# epoll: returns only the 5 FDs with data — 5 checks
```

## Further Reading

- [epoll(7) — man7.org](https://man7.org/linux/man-pages/man7/epoll.7.html) — the definitive reference for epoll: level- vs edge-triggered mode, `EPOLLONESHOT`, `EPOLLEXCLUSIVE` for thundering herd avoidance, interaction with `fork`, and the Q&A section on tricky edge cases.
- [epoll_create1(2) — man7.org](https://man7.org/linux/man-pages/man2/epoll_create1.2.html) — documents the `EPOLL_CLOEXEC` flag, the difference from `epoll_create`, and the file descriptor returned which can itself be added to another epoll instance.
- [Julia Evans — async I/O: select, poll, and epoll](https://jvns.ca/blog/2017/06/03/async-io-on-linux--select--poll--and-epoll/) — accessible comparison of `select`, `poll`, and `epoll` with the O(n) vs O(1) trade-off, edge-triggered pitfalls, and annotated examples of the event loop pattern used by nginx and Redis.
- [The C10K problem — Dan Kegel](http://www.kegel.com/c10k.html) — the seminal 1999 article that motivated epoll's creation; explains why `select`/`poll` hit scaling limits and the design requirements that led to Linux's epoll and FreeBSD's kqueue.
- [LWN — Epoll and the thundering herd](https://lwn.net/Articles/591808/) — analysis of the thundering herd problem with multiple threads calling `epoll_wait` on the same epoll fd, and how `EPOLLEXCLUSIVE` (added in Linux 4.5) solves it for multi-process servers like nginx.
