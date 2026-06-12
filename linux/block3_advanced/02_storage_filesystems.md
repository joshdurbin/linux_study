# Storage and Filesystems

Understanding how Linux organizes storage — block devices, partitions, filesystems, mounts, and inodes — is essential for administration, troubleshooting, and capacity planning.

## df — Filesystem Disk Usage

```bash
df -h                   # human-readable sizes
df -hT                  # include filesystem type
df -i                   # inode usage (can run out of inodes even with space)
df -h /                 # just the root filesystem
df -h --total           # add a totals row
```

Each row: `Filesystem  Size  Used  Avail  Use%  Mounted on`

A filesystem at 100% use% is full. A filesystem at 100% iuse% can't create new files even if there's space.

## lsblk — List Block Devices

```bash
lsblk                   # tree view of block devices
lsblk -f                # include filesystem type and UUID
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,UUID
lsblk /dev/sda          # specific device only
```

## du — Directory Space Usage

```bash
du -sh /var/log         # total size of a directory
du -sh *                # size of each item in current directory
du -h --max-depth=1 /   # first level of the filesystem tree
du -ah /var | sort -rh | head -20  # 20 largest files/dirs
```

## mount and umount

```bash
mount                            # list all currently mounted filesystems
mount | column -t                # formatted output
sudo mount /dev/sdb1 /mnt/data   # mount a device
sudo mount -o ro /dev/sdb1 /mnt  # mount read-only
sudo mount -t ext4 /dev/sdb1 /mnt  # explicit filesystem type
sudo umount /mnt/data            # unmount by mount point
sudo umount /dev/sdb1            # unmount by device
sudo umount -l /mnt              # lazy unmount (when busy)
```

## /etc/fstab — Persistent Mounts

Each line: `device  mountpoint  fstype  options  dump  pass`

```
# Example entries:
UUID=abc123  /          ext4  defaults        0  1
UUID=def456  /home      ext4  defaults        0  2
UUID=ghi789  /boot/efi  vfat  umask=0077      0  1
tmpfs        /tmp       tmpfs nosuid,nodev,noexec  0  0
```

```bash
cat /etc/fstab               # view current fstab
sudo mount -a                # mount all entries in fstab
sudo mount -v -a             # verbose: check for errors
```

Use UUID (not `/dev/sdX`) — device names can change on reboot.

## Inodes

Every file and directory has an inode: a data structure storing metadata (not the filename — that's in the directory entry).

```bash
ls -i file.txt               # show inode number
ls -i /etc/                  # inode numbers for directory contents
stat file.txt                # full inode details
df -i                        # inode usage per filesystem
find . -inum 12345           # find file by inode number
```

Key inode facts:
- Hard links point to the same inode (same data)
- Symlinks are a separate inode pointing to a path
- Inode count is fixed at filesystem creation
- Running out of inodes (even with disk space) prevents file creation

## fsck — Filesystem Check

```bash
sudo fsck /dev/sdb1          # check and repair (must be unmounted!)
sudo fsck -n /dev/sdb1       # check only, no repairs (safe on mounted)
sudo fsck -f /dev/sdb1       # force check even if clean
sudo e2fsck -p /dev/sdb1     # auto-repair ext2/3/4
```

Never run `fsck` on a mounted filesystem (except root with `-n`). Use a live boot environment or rescue mode for the root device.

## Common Filesystem Types

| Type | Use case |
|------|----------|
| ext4 | Linux standard; journaled |
| xfs | High-performance; good for large files |
| btrfs | Copy-on-write; snapshots |
| tmpfs | RAM-backed; cleared on reboot |
| vfat / fat32 | USB drives; Windows compatibility |
| ntfs | Windows drives (read/write via ntfs-3g) |

## Creating Filesystems

```bash
sudo mkfs.ext4 /dev/sdb1         # format as ext4
sudo mkfs.xfs /dev/sdb1          # format as xfs
sudo mkswap /dev/sdb2            # create swap space
sudo swapon /dev/sdb2            # enable swap

# Resize an ext4 filesystem (while mounted)
sudo resize2fs /dev/sda1
```

## Further Reading

- [mount(8) — man7.org](https://man7.org/linux/man-pages/man8/mount.8.html) — definitive reference for every mount flag and option, filesystem-specific options, bind mount semantics, and propagation modes (shared, slave, private).
- [fstab(5) — man7.org](https://man7.org/linux/man-pages/man5/fstab.5.html) — authoritative documentation for every fstab field including dump/pass semantics, UUID vs LABEL vs device path, and `systemd-fstab-generator` integration.
- [Arch Wiki — fstab](https://wiki.archlinux.org/title/Fstab) — practical guide covering UUID-based entries, tmpfs options, bind mounts, and common pitfalls like missing `nofail` for non-critical mounts.
- [Linux kernel filesystem documentation](https://www.kernel.org/doc/html/latest/filesystems/) — kernel.org source-of-truth for ext4, xfs, btrfs, tmpfs, and overlayfs internals, including mount options specific to each filesystem type.
- [Linux inode and VFS internals — LWN](https://lwn.net/Articles/57167/) — explains the VFS layer that unifies all filesystem types under the same `open`/`read`/`write` interface, connecting the `inode` concepts in this lesson to the kernel.
