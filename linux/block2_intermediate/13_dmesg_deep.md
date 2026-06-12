# dmesg — Kernel Ring Buffer

`dmesg` reads the kernel ring buffer: a fixed-size circular buffer in kernel memory where the kernel logs hardware events, driver messages, boot messages, and runtime warnings. It's often the first place to look when hardware misbehaves or the system acts strangely.

## Basic Usage

```bash
dmesg                         # all messages since boot
dmesg | tail -20              # most recent messages
dmesg -T                      # human-readable timestamps (absolute time)
dmesg -H                      # human-readable + relative timestamps + colors
dmesg --follow                # watch in real time (like tail -f)
dmesg -c                      # print and clear the ring buffer (root only)
```

## Filtering by Priority

Linux kernel messages have a facility.priority format. dmesg uses just the priority level:

```
0 emerg    — system unusable
1 alert    — action must be taken immediately
2 crit     — critical conditions
3 err      — error conditions
4 warning  — warning conditions
5 notice   — normal but significant condition
6 info     — informational
7 debug    — debug-level messages
```

```bash
dmesg -l err,crit,emerg       # only errors and above
dmesg -l warn                 # warnings
dmesg -l info                 # informational (very verbose)
dmesg --level=err             # alias
```

## Filtering by Facility

```bash
dmesg -f kern                 # kernel messages
dmesg -f daemon               # daemon messages
dmesg -f user                 # user-space messages
```

## Searching and Grepping

```bash
dmesg -T | grep -i "error"
dmesg -T | grep -i "oom"           # Out of Memory killer events
dmesg -T | grep -i "usb"           # USB device events
dmesg -T | grep -i "eth\|enp\|eno" # network interface events
dmesg -T | grep -i "fail\|error\|warn"
dmesg -T | grep "EXT4\|XFS\|btrfs" # filesystem events
```

## Common Message Patterns

```bash
# OOM killer: which process was killed
dmesg | grep -A5 "Out of memory"

# Disk errors (bad sectors, I/O errors)
dmesg | grep -i "blk_update_request\|I/O error\|hard resetting link"

# NIC issues
dmesg | grep -i "eth0\|enp\|link is"

# CPU microcode updates
dmesg | grep -i "microcode"

# Segfault (process crashed with memory violation)
dmesg | grep "segfault"
# Output: program[PID]: segfault at ADDR ip ADDR sp ADDR error N in binary[...]

# Kernel module loading
dmesg | grep "module\|loaded\|tainted"
```

## Decoding a Kernel Oops

When the kernel hits a fatal error in a module (not a full crash), it logs an "oops":

```
BUG: unable to handle kernel NULL pointer dereference at 0000000000000010
IP: some_function+0x1c/0x50 [my_module]
Call Trace:
 other_function+0x40/0x80
 ...
```

- `IP:` — instruction pointer (where the crash happened)
- `Call Trace:` — kernel stack at the time of crash
- The hex offsets can be decoded with `addr2line` against the kernel build

## journalctl vs dmesg

```bash
journalctl -k                 # kernel messages (same content as dmesg)
journalctl -k -b -1           # kernel messages from the PREVIOUS boot
journalctl -k --since "1 hour ago"

# dmesg timestamps are relative to boot; journalctl -k has wall clock times
```

## /dev/kmsg and /proc/kmsg

```bash
cat /dev/kmsg               # raw kernel log with priority prefix
# Format: priority,seqno,timestamp;<message>

# Write a message to the kernel log (root only)
echo "mytest: hello from userspace" > /dev/kmsg
dmesg | tail -3
```

## Further Reading

- [man7.org — dmesg(1)](https://man7.org/linux/man-pages/man1/dmesg.1.html) — Full flag reference for `dmesg` including `-l`/`-f` filtering, `-T` timestamps, `--follow`, and the `/dev/kmsg` device it reads.
- [Linux Kernel Documentation — Bug hunting](https://www.kernel.org/doc/html/latest/admin-guide/bug-hunting.html) — The official kernel guide to decoding oops messages, reading call traces, and using `addr2line` to locate the crashing source line.
- [Arch Wiki — Kernel — View the kernel ring buffer](https://wiki.archlinux.org/title/Kernel#View_the_kernel_ring_buffer) — Practical guide to reading dmesg output, persistent logging via `journalctl -k`, and configuring the ring buffer size.
- [man7.org — syslog(2)](https://man7.org/linux/man-pages/man2/syslog.2.html) — The kernel syscall for reading and controlling the ring buffer; explains the priority encoding that `dmesg -l` filters on.
- [man7.org — kmsg(3)](https://man7.org/linux/man-pages/man3/kmsg.3.html) — Documents `/dev/kmsg` format: the `priority,seqno,timestamp;message` encoding used for reliable structured kernel log reading.
