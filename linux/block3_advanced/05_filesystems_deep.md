# Filesystems Deep — fstab, Mount Options, and Types

## /etc/fstab — Persistent Mount Configuration

fstab is read by `mount -a` at boot and by `systemd-fstab-generator` which converts entries to systemd `.mount` units.

```
# <device>              <mountpoint>  <type>  <options>           <dump> <pass>
UUID=abc123...          /             ext4    errors=remount-ro   0      1
UUID=def456...          /boot/efi     vfat    umask=0077          0      1
UUID=789abc...          /home         xfs     defaults,noatime    0      2
tmpfs                   /tmp          tmpfs   defaults,size=2G    0      0
//server/share          /mnt/nas      cifs    credentials=/etc/smb.cred,uid=1000  0  0
```

**Always use UUID** — device names (`/dev/sda1`) can change on reboot. Get UUIDs with:
```bash
blkid                        # all block devices with UUIDs
lsblk -f                     # tree view with UUIDs and labels
blkid /dev/sda1              # specific device
```

**pass field:** 0=skip fsck, 1=check first (root only), 2=check after root

## Mount Options

### Common Options (all filesystems)

| Option | Effect |
|--------|--------|
| `defaults` | rw,suid,dev,exec,auto,nouser,async |
| `ro` / `rw` | read-only / read-write |
| `noexec` | prevent execution of binaries |
| `nosuid` | ignore setuid/setgid bits |
| `nodev` | ignore device files |
| `noatime` | don't update access time on reads (performance) |
| `relatime` | update atime only if newer than mtime (default) |
| `lazytime` | batch atime updates (modern default, better performance) |
| `sync` / `async` | synchronous / asynchronous writes |
| `user` / `nouser` | allow/deny non-root mount |
| `auto` / `noauto` | mount with `mount -a` / don't |
| `bind` | bind-mount a directory to another path |

### Bind Mounts

```bash
# Mount a directory at another path (both see the same files)
sudo mount --bind /opt/myapp /var/www/myapp

# In fstab:
/opt/myapp   /var/www/myapp   none   bind   0  0

# Useful for: making a directory available in a chroot/container
```

## Filesystem Types

| Type | Use case | Notes |
|------|----------|-------|
| `ext4` | General purpose, Linux default | journaled, mature, good performance |
| `xfs` | Large files, high throughput | parallel I/O, great for databases |
| `btrfs` | Snapshots, compression, RAID | copy-on-write, still maturing |
| `tmpfs` | RAM-backed temporary storage | lost on reboot, fast |
| `vfat` | EFI partitions, USB drives | FAT32, wide compatibility |
| `iso9660` | CD/DVD images | read-only |
| `nfs` | Network filesystem (Linux NFS server) | requires nfs-common |
| `cifs` | Windows/Samba shares | requires cifs-utils |
| `overlay` | Container layers (Docker) | requires upper/lower/work dirs |

## Creating and Managing Filesystems

```bash
# Create filesystems
sudo mkfs.ext4 /dev/sdb1
sudo mkfs.xfs /dev/sdc1
sudo mkfs.ext4 -L mydata /dev/sdd1   # set label

# Tune ext4 (after creation)
sudo tune2fs -l /dev/sda1            # show filesystem info
sudo tune2fs -c 30 /dev/sda1         # fsck every 30 mounts
sudo tune2fs -e remount-ro /dev/sda1 # remount read-only on error

# Check and repair
sudo fsck /dev/sdb1                  # check (unmounted)
sudo fsck -f /dev/sdb1               # force check even if clean
sudo e2fsck -p /dev/sdb1             # auto-repair
```

## tmpfs — RAM Filesystem

```bash
# Mount a 512MB RAM disk
sudo mount -t tmpfs -o size=512m tmpfs /mnt/ramdisk

# fstab entry
tmpfs   /tmp    tmpfs   defaults,size=2G,mode=1777   0   0
tmpfs   /run    tmpfs   defaults,size=100m,mode=755   0   0

# /dev/shm is already tmpfs
df -h /dev/shm
mount | grep shm
```

## systemd .mount Units

systemd converts fstab entries to `.mount` units and also supports dedicated unit files:

```ini
# /etc/systemd/system/mnt-data.mount
[Unit]
Description=Data Volume

[Mount]
What=/dev/disk/by-uuid/abc123
Where=/mnt/data
Type=ext4
Options=defaults,noatime

[Install]
WantedBy=multi-user.target
```

```bash
# fstab entries are auto-converted
systemctl list-units --type=mount
systemctl status boot.mount
```

## Checking Mount Status

```bash
mount                           # all current mounts (legacy)
findmnt                         # tree view (modern, preferred)
findmnt --verify                # verify fstab entries are mounted
findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS /home
cat /proc/mounts                # kernel's view (always current)
```

## Further Reading

- [Linux kernel filesystem documentation](https://www.kernel.org/doc/html/latest/filesystems/index.html) — kernel.org index of filesystem documentation including ext4, xfs, btrfs, tmpfs, overlayfs, and the VFS layer that unifies them all.
- [mount(8) — man7.org](https://man7.org/linux/man-pages/man8/mount.8.html) — complete mount flag reference including bind mounts, shared/private/slave propagation, namespace interactions, and all filesystem-specific options.
- [ext4 wiki — kernel.org](https://ext4.wiki.kernel.org/) — official ext4 development wiki covering mount options, journal modes (`data=writeback`, `data=ordered`, `data=journal`), and filesystem features like `dir_index` and `extents`.
- [Arch Wiki — Ext4](https://wiki.archlinux.org/title/Ext4) — practical guide to ext4 tuning, `tune2fs` options, `noatime`/`lazytime` trade-offs, and common mount options used to optimize read-heavy or write-heavy workloads.
- [systemd.mount(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.mount.html) — documents how systemd converts fstab entries to `.mount` units and the additional options (like `x-systemd.automount`) available only in systemd-managed mounts.
