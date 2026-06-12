# File Locking

File locking coordinates access to shared files between concurrent processes. Linux provides two systems: **advisory** (processes cooperate by checking locks) and **mandatory** (kernel enforces them regardless). Advisory locking is standard; mandatory locking is largely deprecated.

## flock — Whole-File Advisory Locks

`flock(2)` applies a lock to an entire open file descriptor. The lock is released when the FD is closed or the process exits.

```bash
# Exclusive (write) lock — only one holder at a time
flock(fd, LOCK_EX)

# Shared (read) lock — multiple readers, no writers
flock(fd, LOCK_SH)

# Non-blocking (return EWOULDBLOCK immediately if lock is unavailable)
flock(fd, LOCK_EX | LOCK_NB)

# Release
flock(fd, LOCK_UN)
```

### flock(1) — Shell Command

```bash
# Hold an exclusive lock on a file while running a command
flock /var/lock/myapp.lock ./myapp

# Non-blocking: fail immediately if locked
flock -n /var/lock/myapp.lock ./myapp || echo "Already running"

# Wait up to 10 seconds
flock -w 10 /var/lock/myapp.lock ./myapp

# FD-based (lock is tied to FD 9)
(
    flock -n 9 || exit 1
    echo "Critical section"
) 9>/var/lock/myapp.lock
```

### flock Semantics to Know

```bash
# Locks are per open file description, NOT per process
# A process with two FDs to the same file holds one lock per FD

# Locks are NOT inherited across fork (child gets the same FD but the lock
# isn't transferred separately — the child continues to hold it)

# flock does NOT work across NFS (use lockd/NLM or application-level locking)
# flock works within the same machine across processes

# Verify who holds a lock
flock -n /var/lock/myapp.lock true 2>/dev/null || echo "Lock is held"
```

## fcntl Locks (POSIX Record Locks)

`fcntl(2)` with `F_SETLK`/`F_SETLKW` provides **byte-range locking** — you can lock specific regions of a file, not just the whole file. This is how databases implement concurrent access.

```bash
# fcntl locks are PROCESS-associated, not FD-associated
# If the process closes ANY FD to the file, ALL fcntl locks on that file are released
# This is a known footgun — flock is generally safer in practice

# Check fcntl locks held on files
cat /proc/locks
# Format: lock-id  type  posix  shared/exclusive  pid  major:minor:inode  range
# Example:
# 1: POSIX  ADVISORY  WRITE 1234 08:01:12345 0 EOF
#    │       │         │     │    └── device:inode
#    │       │         │     └── PID holding the lock
#    │       │         └── READ or WRITE
#    │       └── ADVISORY or MANDATORY
#    └── lock number
```

## /proc/locks — Observing All Held Locks

```bash
# View all current locks in the system
cat /proc/locks

# More readable
awk '
{
    type = $2; mode = $4; pid = $5; range = $7 " " $8
    split($6, dev, ":")
    printf "type=%-8s mode=%-6s pid=%-6s dev=%s range=%s\n",
           type, mode, pid, dev[3], range
}
' /proc/locks

# Which files are locked? (requires lsof)
lsof +D / 2>/dev/null | awk '/FLOCK/{print $2, $9}' | head -20

# Find PID holding a lock on a specific file
fuser /var/lock/myapp.lock 2>/dev/null
lsof /var/lock/myapp.lock 2>/dev/null
```

## OFD Locks — Open File Description Locks

Linux 3.15+ added **OFD (Open File Description) locks** via `fcntl F_OFD_SETLK`. These fix the fork footgun of POSIX locks: OFD locks are per-file-description (like flock), not per-process.

```bash
# OFD locks appear in /proc/locks as:
# 1: OFDLCK  ADVISORY  WRITE 1234 ...

# Used by modern databases and file systems internally
# Access via fcntl(F_OFD_SETLK) in C; no direct shell equivalent
```

## Practical Patterns

### Database-Style Range Locking

Databases use byte-range locks to allow multiple writers to different rows in the same file:

```
Row 1: bytes 0-99     → process A holds WRITE lock
Row 2: bytes 100-199  → process B holds WRITE lock (no conflict)
Row 3: bytes 200-299  → process C holds READ lock (compatible with other readers)
```

### Checking if a File is Locked

```bash
# Using flock non-blocking test
file_is_locked() {
    flock -n "$1" true 2>/dev/null
    [ $? -ne 0 ]
}

file_is_locked /var/lock/myapp.lock && echo "locked" || echo "unlocked"

# Using /proc/locks (by inode)
INODE=$(stat -c%i /var/lock/myapp.lock 2>/dev/null)
grep "$INODE" /proc/locks 2>/dev/null && echo "lock entry found" || echo "no lock"
```

### Deadlock Detection

Deadlocks with advisory locks produce processes stuck in D-state:

```bash
# Find processes waiting for file locks
ps aux | awk '$8 == "D" {print $2, $11}'

# Check /proc/locks for contended locks
awk 'NF > 5 {print}' /proc/locks | head -20

# strace a process to see what lock it's waiting on
strace -p $PID -e trace=fcntl,flock 2>&1 | head -10
```

## inotify and Locks

inotify does NOT detect lock acquisitions or releases — lock events are not filesystem events. To detect lock state changes, poll `/proc/locks` or use application-level signaling.

## Further Reading

- [flock(2) — man7.org](https://man7.org/linux/man-pages/man2/flock.2.html) — documents per-open-file-description semantics, NFS non-support, behavior on fork (child shares the same open file description and thus the lock), and the interaction with `dup` and `fork`.
- [fcntl(2) — man7.org](https://man7.org/linux/man-pages/man2/fcntl.2.html) — covers POSIX record locks (`F_SETLK`, `F_SETLKW`, `F_GETLK`), the process-association footgun (all locks released when ANY fd to the file is closed), and the OFD lock API (`F_OFD_SETLK`) that fixes it.
- [LWN — File locking in Linux](https://lwn.net/Articles/586904/) — LWN article comparing `flock`, POSIX record locks, and the newer OFD locks, with analysis of each mechanism's semantics and the historical quirks that led to OFD locks being added.
- [open(2) — man7.org](https://man7.org/linux/man-pages/man2/open.2.html) — the `O_CLOEXEC` flag explanation is key for lock files with `fork`: FDs without `O_CLOEXEC` are inherited across `exec`, potentially allowing a child process to hold locks it doesn't know about.
