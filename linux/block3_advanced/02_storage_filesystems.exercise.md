# Exercise: Storage and Filesystems

## Task 1 — Filesystem overview

Create `~/storagelab/`. Capture filesystem state:

1. Run `df -hT` and save to `~/storagelab/filesystems.txt`
2. Run `lsblk -f` and save to `~/storagelab/block_devices.txt`
3. Run `cat /etc/fstab` and save to `~/storagelab/fstab.txt`

## Task 2 — Mount inspection

Run `mount | grep -v "cgroup\|proc\|sys\|dev\|run"` to show "real" filesystem mounts (filtering out virtual ones) and save to `~/storagelab/mounts.txt`.

Then extract just the mount points (field 3, space-delimited) from `mount` output and sort them:

```bash
mount | awk '{print $3}' | sort -u > ~/storagelab/mountpoints.txt
```

## Task 3 — Inode exploration

1. Run `df -i` and save to `~/storagelab/inodes.txt`
2. Create three files: `~/storagelab/a.txt`, `~/storagelab/b.txt`, `~/storagelab/c.txt`
3. Create a hard link: `ln ~/storagelab/a.txt ~/storagelab/a_hardlink.txt`
4. Run `ls -i ~/storagelab/` and save to `~/storagelab/inode_listing.txt`

Verify that `a.txt` and `a_hardlink.txt` have the same inode number (visible in the listing).

## Task 4 — du deep dive

1. Run `du -sh /etc /var /tmp` (suppress permission errors with `2>/dev/null`) and save to `~/storagelab/dir_usage.txt`
2. Find the 10 largest files under `/usr/lib` using `du -ah /usr/lib 2>/dev/null | sort -rh | head -10` and save to `~/storagelab/largest_lib_files.txt`
