# Exercise: LVM

> Full LVM requires block devices. These exercises use documentation tasks + inspection of existing LVM if present.

## Tasks

1. **Check for existing LVM**: Inspect the running system for LVM:
   ```bash
   {
     echo "=== Physical Volumes ==="
     sudo pvs 2>/dev/null || echo "no PVs found"
     echo "=== Volume Groups ==="
     sudo vgs 2>/dev/null || echo "no VGs found"
     echo "=== Logical Volumes ==="
     sudo lvs 2>/dev/null || echo "no LVs found"
     echo "=== dm devices ==="
     ls /dev/mapper/ 2>/dev/null
   } > ~/practice/lvm_inventory.txt
   ```

2. **LVM on root**: Check if the root filesystem uses LVM:
   ```bash
   {
     echo "Root device: $(findmnt -n -o SOURCE /)"
     echo "Device type:"
     lsblk -o NAME,TYPE,FSTYPE,MOUNTPOINT $(findmnt -n -o SOURCE /) 2>/dev/null || true
   } > ~/practice/lvm_root.txt
   ```

3. **Write the LVM creation workflow**: Document the exact commands to set up LVM on two new disks (`/dev/sdb` and `/dev/sdc`) with a 50GB logical volume called `appdata` in a VG called `datavg`:
   ```bash
   cat > ~/practice/lvm_workflow.txt << 'EOF'
   # Step 1: Create Physical Volumes
   sudo pvcreate /dev/sdb /dev/sdc
   
   # Step 2: Create Volume Group
   sudo vgcreate datavg /dev/sdb /dev/sdc
   
   # Step 3: Create Logical Volume (50GB)
   sudo lvcreate -L 50G -n appdata datavg
   
   # Step 4: Format
   sudo mkfs.ext4 /dev/datavg/appdata
   
   # Step 5: Mount
   sudo mkdir -p /mnt/appdata
   sudo mount /dev/datavg/appdata /mnt/appdata
   
   # Step 6: fstab entry for persistence
   # /dev/datavg/appdata  /mnt/appdata  ext4  defaults  0 2
   EOF
   ```

4. **Online extend workflow**: Write the commands to extend the `appdata` LV by 20GB and resize the ext4 filesystem online:
   ```bash
   cat > ~/practice/lvm_extend.txt << 'EOF'
   # Extend LV by 20GB
   sudo lvextend -L +20G /dev/datavg/appdata
   
   # Resize ext4 filesystem online (no unmount needed)
   sudo resize2fs /dev/datavg/appdata
   
   # Or do both in one step
   sudo lvextend -L +20G --resizefs /dev/datavg/appdata
   
   # For XFS (must use mount point, not device)
   sudo xfs_growfs /mnt/appdata
   EOF
   ```

5. **Snapshot use case**: Write `~/practice/lvm_snapshot.txt` explaining when you'd use an LVM snapshot vs a filesystem-level backup, and the commands to create, mount, and merge a snapshot.

## Hints

- `pvs`, `vgs`, `lvs` are the quick status commands; `pvdisplay`, `vgdisplay`, `lvdisplay` are verbose
- LV device path: `/dev/VGname/LVname` (symlink to `/dev/mapper/VGname-LVname`)
- Always shrink the filesystem BEFORE shrinking the LV — reverse order destroys data
- `--resizefs` flag on `lvextend` handles both steps for ext2/3/4
