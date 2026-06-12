# Exercise: Filesystems, fstab, and Mount Options

## Tasks

1. **Inventory mounts**: Use `findmnt` to get the current mount tree and `blkid` for device info:
   ```bash
   findmnt > ~/practice/mounts_tree.txt
   blkid 2>/dev/null >> ~/practice/mounts_tree.txt || sudo blkid >> ~/practice/mounts_tree.txt
   ```

2. **Read fstab**: Copy and annotate `/etc/fstab`:
   ```bash
   cat /etc/fstab > ~/practice/fstab_copy.txt
   echo "---" >> ~/practice/fstab_copy.txt
   echo "Number of entries: $(grep -vc '^#\|^$' /etc/fstab)" >> ~/practice/fstab_copy.txt
   ```

3. **Create a tmpfs**: Mount a small RAM disk and write a file to it:
   ```bash
   sudo mkdir -p /mnt/ramdisk
   sudo mount -t tmpfs -o size=32m tmpfs /mnt/ramdisk
   echo "tmpfs test data" > /mnt/ramdisk/test.txt
   df -h /mnt/ramdisk > ~/practice/tmpfs_test.txt
   cat /mnt/ramdisk/test.txt >> ~/practice/tmpfs_test.txt
   sudo umount /mnt/ramdisk
   ```

4. **Write an fstab line**: Write `~/practice/fstab_examples.txt` with 3 valid fstab lines for:
   - An ext4 root filesystem using UUID with `errors=remount-ro`
   - A 2GB tmpfs on `/tmp` with `mode=1777`
   - A bind mount of `/opt/app` to `/srv/app`

5. **Filesystem info**: Get info on a mounted ext4 or xfs filesystem:
   ```bash
   FS=$(findmnt -n -o SOURCE / 2>/dev/null)
   sudo tune2fs -l "$FS" 2>/dev/null | head -20 > ~/practice/fs_info.txt || \
   sudo xfs_info / 2>/dev/null > ~/practice/fs_info.txt || \
   echo "filesystem info not available in this environment" > ~/practice/fs_info.txt
   ```

## Hints

- `findmnt` is the modern replacement for `mount` — cleaner output, supports filtering
- `blkid` may need sudo to see all devices
- tmpfs files disappear on unmount — that's the whole point
- fstab `pass` field: 0=skip fsck, 1=root first, 2=check after root
