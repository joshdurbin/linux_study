# The /proc Filesystem

## What is /proc?

`/proc` is a **virtual filesystem** — it exists entirely in memory and is never written to disk. The kernel generates its contents on demand every time you read from it. It serves as a window into the running kernel and all active processes.

Mount it yourself to see how it works:
```bash
mount | grep proc
# proc on /proc type proc (rw,nosuid,nodev,noexec,relatime)
```

## Key Top-Level Files

### System Information

```bash
# CPU information: model, cores, flags
cat /proc/cpuinfo

# Memory statistics (in kB)
cat /proc/meminfo

# Kernel version + build info
cat /proc/version

# Seconds since boot, idle seconds
cat /proc/uptime

# 1-min, 5-min, 15-min load avg, running/total tasks, last PID
cat /proc/loadavg

# Currently mounted filesystems (like /etc/mtab but always current)
cat /proc/mounts
```

### Parsing Specific Values

```bash
# Get MemAvailable in human terms
grep MemAvailable /proc/meminfo

# Number of CPUs
grep -c ^processor /proc/cpuinfo

# Load average only
cut -d' ' -f1-3 /proc/loadavg
```

## Per-Process Directories: /proc/PID/

Every running process has a directory at `/proc/<PID>/`. Use `$$` for the current shell's PID.

```bash
ls /proc/$$
```

### Important Files Under /proc/PID/

| File | Contents |
|------|----------|
| `cmdline` | Full command + arguments (null-separated) |
| `status` | Human-readable process state, memory, UIDs |
| `stat` | Machine-readable stats (used by `ps`, `top`) |
| `fd/` | Directory of symlinks to open file descriptors |
| `maps` | Memory map: address ranges, permissions, backing files |
| `environ` | Environment variables (null-separated) |
| `exe` | Symlink to the executable binary |
| `cwd` | Symlink to the current working directory |
| `net/` | Network stats for this process's namespace |

### Reading Per-Process Files

```bash
# Command line of PID 1 (init/systemd)
cat /proc/1/cmdline | tr '\0' ' '

# Status of the current shell
cat /proc/$$/status

# Open file descriptors of the current shell
ls -la /proc/$$/fd

# Memory map of the current shell
cat /proc/$$/maps | head -20

# Environment of the current shell
cat /proc/$$/environ | tr '\0' '\n' | grep HOME
```

### The /proc/self Shortcut

`/proc/self` always points to the current process — no need to know your PID:

```bash
cat /proc/self/cmdline | tr '\0' ' '
ls /proc/self/fd
cat /proc/self/status
```

## Exploring File Descriptors

Every process starts with three standard FDs: 0 (stdin), 1 (stdout), 2 (stderr). Additional FDs are opened as the process opens files, sockets, pipes, etc.

```bash
# Count open FDs for PID 1
ls /proc/1/fd | wc -l

# What files does bash have open?
ls -la /proc/$$/fd

# Find which FD points to a terminal
readlink /proc/$$/fd/0
```

## Reading /proc/meminfo

Key fields to understand:

- **MemTotal**: Total RAM installed
- **MemFree**: Completely unused RAM
- **MemAvailable**: RAM available for new processes (includes reclaimable cache) — use this, not MemFree
- **Buffers**: Kernel buffer cache (metadata)
- **Cached**: Page cache (file data)
- **SwapTotal / SwapFree**: Swap space
- **Dirty**: Data written to page cache but not yet flushed to disk

```bash
# Quick memory summary
awk '/MemTotal|MemAvailable|SwapFree/ {printf "%-15s %s %s\n", $1, $2, $3}' /proc/meminfo
```

## Why /proc Matters

Tools like `ps`, `top`, `htop`, `lsof`, `strace`, and `netstat` all read from `/proc`. Understanding `/proc` means you can get the same information directly without installing extra tools — useful when debugging a minimal container or emergency system.

## Further Reading

- [proc(5) — man7.org](https://man7.org/linux/man-pages/man5/proc.5.html) — the authoritative reference for every file under `/proc`: field meanings in `/proc/meminfo`, `/proc/stat`, `/proc/PID/status`, `/proc/PID/maps`, and the `/proc/net/` subtree.
- [procfs documentation — kernel.org](https://www.kernel.org/doc/html/latest/filesystems/proc.html) — kernel.org documentation on the procfs implementation: how entries are generated on demand, the `seq_file` interface, and what the `/proc/sys/` files actually control.
- [linux-insides — /proc chapter](https://0xax.gitbooks.io/linux-insides/content/) — covers the virtual filesystem layer and how the kernel registers `/proc` entries, populating them when userspace reads them.
- [LWN — /proc and sysfs](https://lwn.net/Articles/57232/) — early LWN article explaining the design rationale for `/proc`, its evolution, and the push to move kernel parameters to `/sys` to address the historical messiness of `/proc`.
