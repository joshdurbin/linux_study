# LVM — Logical Volume Manager

LVM adds a flexible abstraction layer between physical disks and filesystems. It enables resizing volumes without downtime, spanning volumes across multiple disks, and snapshots.

## The Three Layers

```
Physical Disks/Partitions
  └── Physical Volumes (PV)   — raw block devices registered with LVM
        └── Volume Group (VG) — pool of storage from one or more PVs
              └── Logical Volumes (LV) — virtual block devices you format and mount
```

```bash
# Full status overview
sudo pvs      # physical volumes
sudo vgs      # volume groups
sudo lvs      # logical volumes
sudo pvdisplay  # detailed PV info
sudo vgdisplay  # detailed VG info
sudo lvdisplay  # detailed LV info
```

## Creating an LVM Setup

```bash
# 1. Create Physical Volumes
sudo pvcreate /dev/sdb /dev/sdc

# 2. Create a Volume Group from those PVs
sudo vgcreate datavg /dev/sdb /dev/sdc

# 3. Create Logical Volumes from the VG
sudo lvcreate -L 50G -n appdata datavg        # 50GB fixed size
sudo lvcreate -l 100%FREE -n backup datavg    # all remaining space
sudo lvcreate -l 80%VG -n logs datavg         # 80% of total VG

# 4. Format and mount
sudo mkfs.ext4 /dev/datavg/appdata
sudo mount /dev/datavg/appdata /mnt/appdata

# fstab entry
# /dev/datavg/appdata   /mnt/appdata   ext4   defaults   0 2
```

LV device paths: `/dev/VGname/LVname` or `/dev/mapper/VGname-LVname`

## Extending Volumes (Online, No Downtime)

```bash
# Extend LV by 10GB
sudo lvextend -L +10G /dev/datavg/appdata

# Extend LV to use all free space in the VG
sudo lvextend -l +100%FREE /dev/datavg/appdata

# Resize the filesystem after extending the LV
sudo resize2fs /dev/datavg/appdata        # ext4
sudo xfs_growfs /mnt/appdata              # xfs (use mount point, not device)

# Do both in one command (ext4 only)
sudo lvextend -L +10G --resizefs /dev/datavg/appdata
```

## Shrinking (Requires Unmount + Caution)

```bash
# Shrink ext4 filesystem FIRST (xfs cannot shrink)
sudo umount /mnt/appdata
sudo e2fsck -f /dev/datavg/appdata
sudo resize2fs /dev/datavg/appdata 40G    # shrink FS to 40GB first
sudo lvreduce -L 40G /dev/datavg/appdata  # then shrink LV
sudo mount /dev/datavg/appdata /mnt/appdata
```

## Adding a Disk to an Existing VG

```bash
sudo pvcreate /dev/sdd
sudo vgextend datavg /dev/sdd
sudo vgs  # verify increased size
```

## Snapshots

```bash
# Create a snapshot (point-in-time copy, uses CoW)
sudo lvcreate -L 5G -s -n appdata_snap /dev/datavg/appdata

# Mount the snapshot read-only
sudo mount -o ro /dev/datavg/appdata_snap /mnt/snap

# Restore from snapshot (appdata must be unmounted)
sudo lvconvert --merge /dev/datavg/appdata_snap

# Remove snapshot
sudo lvremove /dev/datavg/appdata_snap
```

Snapshots only store changed blocks — size depends on write activity, not LV size.

## Thin Provisioning

```bash
# Create a thin pool (allocates space on demand)
sudo lvcreate -L 100G --thinpool thinpool datavg

# Create thin volumes from the pool (can over-provision)
sudo lvcreate -V 200G --thin -n app1 datavg/thinpool
sudo lvcreate -V 200G --thin -n app2 datavg/thinpool
# Total allocated: 400G from a 100G pool — works until data fills the pool
```

## Moving PVs and Removing Disks

```bash
# Move all data off a PV before removing it
sudo pvmove /dev/sdb

# Remove PV from VG (after pvmove)
sudo vgreduce datavg /dev/sdb
sudo pvremove /dev/sdb
```

## Further Reading

- [LVM HOWTO — TLDP](https://tldp.org/HOWTO/LVM-HOWTO/) — the classic step-by-step guide to LVM: creating PVs, VGs, and LVs; resizing; snapshots; and migrating data between disks with `pvmove`.
- [lvm(8) — man7.org](https://man7.org/linux/man-pages/man8/lvm.8.html) — authoritative command reference covering every LVM subcommand, the `lvm.conf` configuration file, and the device-mapper target naming conventions.
- [Red Hat LVM Administration Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_logical_volumes/) — comprehensive production guide covering thin provisioning, snapshots, RAID logical volumes via `--type raid5`, and VDO deduplication on LVM.
- [Arch Wiki — LVM](https://wiki.archlinux.org/title/LVM) — practical LVM reference with coverage of LVM on LUKS, thin pools, lvmcache (SSD caching), and common pitfalls when booting from LVM volumes.
- [device-mapper documentation — kernel.org](https://www.kernel.org/doc/html/latest/admin-guide/device-mapper/) — kernel documentation for the device-mapper subsystem that LVM's logical volumes, snapshots, and thin pools are built on top of.
