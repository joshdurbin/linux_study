# lsof — List Open Files

`lsof` (List Open Files) shows every file descriptor open on the system. On Linux, "everything is a file" — so lsof reveals open regular files, sockets, pipes, devices, and more.

## Key Concepts

lsof reads from `/proc/PID/fd/` and `/proc/PID/fdinfo/`. Each entry represents one file descriptor.

Output columns:
```
COMMAND  PID   USER   FD   TYPE   DEVICE  SIZE/OFF  NODE  NAME
nginx    1234  www    4u   IPv4   12345   0t0        TCP   *:80 (LISTEN)
bash     5678  alice  1u   CHR    136,1   0t0        3     /dev/pts/1
python   9012  bob    3r   REG    8,1     4096       555   /etc/config.yaml
```

- `FD`: file descriptor number + mode: `r`=read, `w`=write, `u`=read+write
- `TYPE`: REG=file, DIR=directory, CHR=character device, IPv4/IPv6=socket, FIFO=pipe, unix=Unix socket
- `NAME`: path, or `(deleted)` if the file has been unlinked

## Network Connections

```bash
lsof -i                       # all network connections
lsof -i TCP                   # TCP only
lsof -i UDP                   # UDP only
lsof -i :80                   # what's using port 80
lsof -i :22 -i :443           # multiple ports
lsof -i TCP:1-1024            # all TCP ports in range
lsof -i @192.168.1.1          # connections to a specific host
lsof -i TCP -s TCP:LISTEN     # only LISTEN state (like ss -tlnp)
lsof -i TCP -s TCP:ESTABLISHED
```

## Per-Process

```bash
lsof -p 1234                  # all FDs for PID 1234
lsof -p 1234,5678             # multiple PIDs
lsof -c nginx                 # all processes whose name starts with "nginx"
lsof -c /regexp/              # processes matching a regex
```

## Per-File or Directory

```bash
lsof /var/log/syslog          # which processes have this file open
lsof +D /var/log              # all files open under this directory tree
lsof +d /tmp                  # all files open directly in /tmp (not recursive)
```

## By User

```bash
lsof -u alice                 # all files opened by user alice
lsof -u ^root                 # everyone except root
```

## Finding Deleted Files Holding Disk Space

This is one of lsof's most practical uses — a log file is deleted but a process still holds it open, consuming disk space:

```bash
lsof +L1                      # files with link count < 1 (deleted but open)
lsof +L1 | grep deleted       # filter to explicitly deleted
lsof +L1 | awk '{print $7}' | sort -rh | head  # sort by size

# To recover space: restart the process holding the deleted file,
# OR zero it out: > /proc/PID/fd/FD_NUMBER
```

## FD Limit Monitoring

```bash
# How many FDs is a process using?
ls /proc/1234/fd | wc -l

# What's the FD limit?
cat /proc/1234/limits | grep "Open files"

# System-wide FD usage
cat /proc/sys/fs/file-nr
# format: used  unused_but_reserved  max
```

## Useful Combinations

```bash
# What process is listening on a port
lsof -i :8080 -sTCP:LISTEN -nP

# What files does a container's PID have open
sudo lsof -p $(docker inspect -f '{{.State.Pid}}' mycontainer) 2>/dev/null | head -30

# Memory-mapped files (what's loaded into memory)
lsof -p $$ | grep mem

# Watch for new connections in real time
watch -n1 'lsof -i TCP -sTCP:ESTABLISHED -nP'

# Find who wrote to a file recently (combine with inotifywait)
lsof /path/to/file
```

## Further Reading

- [lsof(8) man page](https://man7.org/linux/man-pages/man8/lsof.8.html) — The authoritative reference for every lsof flag, output column (FD, TYPE, NODE, NAME), and filter expression (`-i`, `+L1`, `+D`, `-u`, `-c`) used in this lesson.
- [proc(5) man page — /proc/PID/fd](https://man7.org/linux/man-pages/man5/proc.5.html) — Documents the `/proc/PID/fd/` symlink directory and `/proc/PID/fdinfo/` files that lsof reads to enumerate open file descriptors, sockets, and pipes.
- [Julia Evans: lsof — "Everything is a file" in action](https://jvns.ca/blog/2016/12/03/linux-memory-pressure/) — Explains how lsof's "everything is a file" view enables investigating deleted files, socket leaks, and memory-mapped regions in a single tool.
