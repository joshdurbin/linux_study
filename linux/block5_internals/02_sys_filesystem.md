# The /sys Filesystem and sysctl

## What is /sys?

`/sys` is **sysfs** — another virtual filesystem that exposes the kernel's internal object model. While `/proc` is largely process-oriented (and historically messy), `/sys` was designed to expose the kernel's device and driver model cleanly as a hierarchy of objects and attributes.

```bash
mount | grep sysfs
# sysfs on /sys type sysfs (rw,nosuid,nodev,noexec,relatime)
```

## Key Subdirectories of /sys

| Path | Contents |
|------|----------|
| `/sys/class/` | Devices grouped by type (net, block, tty, etc.) |
| `/sys/block/` | Block devices (disks, partitions) |
| `/sys/bus/` | Buses (PCI, USB, platform) and attached devices |
| `/sys/devices/` | The full device tree (hierarchical) |
| `/sys/kernel/` | Kernel internals (cgroups, debug, mm) |
| `/sys/module/` | Loaded kernel modules and their parameters |
| `/sys/net/` | Symlink to `/sys/class/net/` |

### Exploring Network Interfaces via /sys

```bash
ls /sys/class/net/
# lo  eth0  (or enp0s3, etc.)

# Interface speed (in Mb/s)
cat /sys/class/net/eth0/speed 2>/dev/null

# MAC address
cat /sys/class/net/eth0/address

# Interface operational state
cat /sys/class/net/eth0/operstate

# TX/RX statistics
cat /sys/class/net/eth0/statistics/rx_bytes
cat /sys/class/net/eth0/statistics/tx_packets
```

### Exploring Block Devices via /sys

```bash
ls /sys/block/
# sda  vda  (disk names)

cat /sys/block/sda/size          # size in 512-byte sectors
cat /sys/block/sda/queue/scheduler  # I/O scheduler (mq-deadline, none, etc.)
```

## sysctl: Reading and Writing Kernel Parameters

Kernel parameters live under `/proc/sys/` as files, but the `sysctl` command provides a cleaner interface. Each dot in a sysctl key maps to a `/` in the path:

`net.ipv4.ip_forward` → `/proc/sys/net/ipv4/ip_forward`

### Reading Parameters

```bash
# Read a single parameter
sysctl vm.swappiness
sysctl net.ipv4.ip_forward

# Read all parameters
sysctl -a

# Read all and filter
sysctl -a | grep net.ipv4

# Read directly from /proc/sys
cat /proc/sys/vm/swappiness
```

### Writing Parameters (Temporary — Lost on Reboot)

```bash
# Set swappiness to 10 (less aggressive swapping)
sudo sysctl -w vm.swappiness=10

# Enable IP forwarding (needed for routing/NAT)
sudo sysctl -w net.ipv4.ip_forward=1

# Or write directly to the file
echo 10 | sudo tee /proc/sys/vm/swappiness
```

### Making Changes Permanent

Edit `/etc/sysctl.conf` or add a file to `/etc/sysctl.d/`:

```bash
# /etc/sysctl.d/99-custom.conf
vm.swappiness = 10
net.ipv4.ip_forward = 1
fs.file-max = 2097152
```

Apply without rebooting:
```bash
sudo sysctl -p /etc/sysctl.d/99-custom.conf
```

## Further Reading

- [sysfs documentation — kernel.org](https://www.kernel.org/doc/html/latest/filesystems/sysfs.html) — kernel.org specification for the sysfs filesystem: kobject/ktype/kset model, attribute files, how to read and write them, and the rules for stable ABI.
- [sysfs rules — kernel.org](https://www.kernel.org/doc/html/latest/admin-guide/sysfs-rules.html) — the kernel's own guidelines for userspace tools reading sysfs: which paths are stable ABI, how to use `/sys/class/` vs `/sys/devices/`, and symlink resolution.
- [sysctl documentation — kernel.org](https://www.kernel.org/doc/html/latest/admin-guide/sysctl/) — kernel documentation for every `/proc/sys/` subtree (`vm`, `net`, `kernel`, `fs`) — the parameters directly beneath `/sys` that `sysctl` manages.
- [sysfs(5) — man7.org](https://man7.org/linux/man-pages/man5/sysfs.5.html) — man page covering the sysfs mount point, the `/sys/class/`, `/sys/block/`, `/sys/bus/`, and `/sys/devices/` hierarchies used in the lesson's network and block device examples.

## Common Tunables

### Memory Management

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `vm.swappiness` | 60 | How aggressively to swap (0=avoid swap, 100=swap often) |
| `vm.dirty_ratio` | 20 | % of RAM that can be dirty before blocking writes |
| `vm.overcommit_memory` | 0 | Memory overcommit policy |

### Networking

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `net.ipv4.ip_forward` | 0 | Enable/disable packet forwarding (required for routing) |
| `net.core.somaxconn` | 4096 | Max listen backlog for sockets |
| `net.ipv4.tcp_syncookies` | 1 | SYN flood protection |
| `net.ipv4.tcp_fin_timeout` | 60 | Seconds to hold FIN_WAIT2 state |

### File System

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `fs.file-max` | ~800000 | System-wide max open file descriptors |
| `fs.inotify.max_user_watches` | 8192 | Max inotify watches per user |

### Kernel

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `kernel.pid_max` | 32768 | Maximum PID value |
| `kernel.dmesg_restrict` | 1 | Restrict dmesg to root only |

## Practical Use Cases

```bash
# Check if this system can route packets
sysctl net.ipv4.ip_forward

# Check how aggressively the kernel swaps
sysctl vm.swappiness

# Check max file descriptors allowed system-wide
sysctl fs.file-max

# See current open fd count vs limit
cat /proc/sys/fs/file-nr
# format: open_fds  unused_fds  max_fds
```
