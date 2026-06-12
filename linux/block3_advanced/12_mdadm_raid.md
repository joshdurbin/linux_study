# Software RAID with mdadm

Linux's `md` (multiple devices) driver provides software RAID in the kernel. Unlike hardware RAID, software RAID is portable (the metadata travels with the disks), transparent to the filesystem, and fully observable.

## RAID Levels

| Level | Min Disks | Redundancy | Usable Capacity | Notes |
|-------|-----------|------------|-----------------|-------|
| RAID 0 | 2 | None | 100% (n × disk) | Striping only — performance, no protection |
| RAID 1 | 2 | 1 disk failure | 50% (1 × disk) | Mirroring — simple, good for boot |
| RAID 5 | 3 | 1 disk failure | (n-1)/n | Distributed parity — balanced |
| RAID 6 | 4 | 2 disk failures | (n-2)/n | Double parity — safer than RAID 5 |
| RAID 10 | 4 | 1 disk per mirror | 50% | Stripe of mirrors — best performance + redundancy |

## /proc/mdstat — Array Status

```bash
cat /proc/mdstat
# Personalities : [raid1] [raid5] [raid6]
# md0 : active raid1 sdb[0] sdc[1]
#       1048576000 blocks super 1.2 [2/2] [UU]
#       bitmap: 0/8 pages [0KB], 65536KB chunk
#
# md1 : active raid5 sdd[0] sde[1] sdf[2]
#       2097152000 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/3] [UUU]
#
# unused devices: <none>

# [UU] = both drives healthy; [U_] = one drive missing/failed
# Resync progress appears here during rebuild
```

## mdadm — Creating and Managing Arrays

### Creating a RAID Array (on loop devices for practice)

```bash
# Create loop devices from files
for i in 1 2 3; do
    dd if=/dev/zero of=/tmp/raid_disk$i.img bs=1M count=100
    sudo losetup /dev/loop$((i+10)) /tmp/raid_disk$i.img
done

# Create RAID 1 (mirror) on loop devices
sudo mdadm --create /dev/md0 \
    --level=1 \
    --raid-devices=2 \
    /dev/loop11 /dev/loop12

# Create RAID 5
sudo mdadm --create /dev/md1 \
    --level=5 \
    --raid-devices=3 \
    --chunk=512K \
    /dev/loop11 /dev/loop12 /dev/loop13
```

### Array Information

```bash
# Full array details
sudo mdadm --detail /dev/md0

# Disks in an array
sudo mdadm --examine /dev/sdb   # check if a disk is part of an array

# Brief status
cat /proc/mdstat

# Array UUID and superblock info
sudo mdadm --examine /dev/sdb | grep UUID
```

### Assembling an Array at Boot

```bash
# Save the config (needed for boot)
sudo mdadm --detail --scan | sudo tee /etc/mdadm/mdadm.conf

# Assemble all arrays defined in config
sudo mdadm --assemble --scan

# Assemble a specific array
sudo mdadm --assemble /dev/md0 /dev/sdb /dev/sdc
```

## Simulating and Recovering from Drive Failure

```bash
# Mark a disk as failed (simulate failure)
sudo mdadm /dev/md0 --fail /dev/sdc

# Check the degraded state
cat /proc/mdstat    # [U_] shows one drive missing
sudo mdadm --detail /dev/md0

# Remove the failed disk from the array
sudo mdadm /dev/md0 --remove /dev/sdc

# Add a replacement disk
sudo mdadm /dev/md0 --add /dev/sdd

# Watch the rebuild progress
watch -n2 cat /proc/mdstat
# Rebuild progress: [=====>..........] sync = 35.2% ...
```

## RAID Monitoring

```bash
# Enable email alerts for RAID events (put in /etc/mdadm/mdadm.conf)
MAILADDR admin@example.com

# Start monitoring daemon
sudo mdadm --monitor --daemonise --mail=admin@example.com --delay=300 /dev/md0

# Test monitoring (sends a test email)
sudo mdadm --monitor --test /dev/md0

# Check monitoring process
pgrep -a mdadm
```

## /proc/mdstat Fields Decoded

```
md0 : active raid1 sdb[0] sdc[1]
│      │           │         │
│      │           │         └── disk index in array
│      │           └── member devices (disk[index])
│      └── RAID level
└── array name

      1048576000 blocks super 1.2 [2/2] [UU]
                                   │      │
                                   │      └── U=up, _=failed/missing (one per disk)
                                   └── [active/configured]

      [==>..................]  check = 14.1% (...)  finish=2.0min speed=100K/sec
         └── progress bar (during sync, check, or rebuild)
```

## Growing an Array

```bash
# Add a disk to expand RAID 5/6 to more members
sudo mdadm /dev/md1 --add /dev/sdg
sudo mdadm --grow /dev/md1 --raid-devices=4   # expand from 3 to 4 devices

# Expand the filesystem after growing
sudo resize2fs /dev/md1     # if ext4
# or: xfs_growfs /mnt/point  # if XFS (must be mounted)
```

## Filesystem on RAID — Alignment

```bash
# Format with alignment matching RAID chunk size (512K example)
sudo mkfs.ext4 -b 4096 -E stride=128,stripe-width=384 /dev/md1
#                            stride = chunk/block = 512K/4K = 128
#                            stripe-width = stride × data_disks = 128 × 3 = 384

# For XFS
sudo mkfs.xfs -d su=512k,sw=3 /dev/md1
```

## Further Reading

- [mdadm(8) — man7.org](https://man7.org/linux/man-pages/man8/mdadm.8.html) — complete `mdadm` reference covering `--create`, `--detail`, `--examine`, `--grow`, `--monitor`, superblock versions (0.9, 1.0, 1.2), and all array management subcommands.
- [Linux RAID wiki — kernel.org](https://raid.wiki.kernel.org/) — the official kernel.org RAID wiki covering RAID level selection, chunk size tuning, write-intent bitmaps, and reshape/grow operations.
- [Arch Wiki — RAID](https://wiki.archlinux.org/title/RAID) — practical RAID guide covering array creation, `/etc/mdadm.conf` persistence, filesystem alignment for RAID 5/6, and recovery procedures for degraded arrays.
- [md driver documentation — kernel.org](https://www.kernel.org/doc/html/latest/driver-api/md/md.html) — kernel documentation for the md driver: `/proc/mdstat` field meanings, sysfs interface for online reshape, and the write-intent bitmap format.
