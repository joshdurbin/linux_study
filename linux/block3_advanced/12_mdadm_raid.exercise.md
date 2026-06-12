# Exercise: Software RAID with mdadm

## Setup

```bash
mkdir -p ~/practice/raid
sudo apt-get install -y mdadm 2>/dev/null || true
```

## Task 1: Check mdadm and Current RAID Status

```bash
mdadm --version 2>/dev/null || echo "mdadm not installed"

echo ""
echo "=== Current RAID Arrays ==="
cat /proc/mdstat
```

## Task 2: Create Disk Images for Practice

```bash
cd ~/practice/raid

# Create three 64MB disk images
for i in 1 2 3; do
    dd if=/dev/zero of=disk${i}.img bs=1M count=64 status=none
    echo "Created disk${i}.img"
done
ls -lh ~/practice/raid/disk*.img
```

## Task 3: Set Up Loop Devices

```bash
cd ~/practice/raid

# Attach loop devices
LOOP1=$(sudo losetup -f --show disk1.img)
LOOP2=$(sudo losetup -f --show disk2.img)
LOOP3=$(sudo losetup -f --show disk3.img)
echo "Loop devices: $LOOP1 $LOOP2 $LOOP3"

# Save for later tasks
echo "$LOOP1 $LOOP2 $LOOP3" > ~/practice/raid/loops.txt
cat ~/practice/raid/loops.txt
```

## Task 4: Create a RAID 1 Array

```bash
read LOOP1 LOOP2 LOOP3 < ~/practice/raid/loops.txt

# Create RAID 1 (mirror) using two of the loop devices
sudo mdadm --create /dev/md10 \
    --level=1 \
    --raid-devices=2 \
    --metadata=1.2 \
    "$LOOP1" "$LOOP2" \
    --run

echo "RAID 1 array created:"
cat /proc/mdstat | grep -A5 md10
sudo mdadm --detail /dev/md10 2>/dev/null | head -20
```

## Task 5: Format and Use the RAID Array

```bash
# Format the RAID device
sudo mkfs.ext4 /dev/md10

# Mount and write data
sudo mkdir -p /mnt/raid_test
sudo mount /dev/md10 /mnt/raid_test
echo "RAID 1 data" | sudo tee /mnt/raid_test/test.txt
df -h /mnt/raid_test
```

## Task 6: Simulate a Drive Failure and Recovery

```bash
read LOOP1 LOOP2 LOOP3 < ~/practice/raid/loops.txt

echo "=== Before failure ==="
cat /proc/mdstat | grep md10

# Mark loop1 as failed
sudo mdadm /dev/md10 --fail "$LOOP1"
echo ""
echo "=== After failure ==="
cat /proc/mdstat | grep md10
sudo mdadm --detail /dev/md10 2>/dev/null | grep -E "State|Active|Failed|Spare|$LOOP"

# Verify data is still accessible (RAID 1 still has the mirror)
cat /mnt/raid_test/test.txt

# Remove the failed disk
sudo mdadm /dev/md10 --remove "$LOOP1"

# Add a replacement (use loop3)
sudo mdadm /dev/md10 --add "$LOOP3"

echo ""
echo "=== After adding replacement (rebuilding) ==="
cat /proc/mdstat | grep -A3 md10
```

## Task 7: Monitor Rebuild Progress

```bash
# Watch for a few seconds to see rebuild
for i in 1 2 3 4 5; do
    echo "$(date +%H:%M:%S): $(grep -A2 md10 /proc/mdstat | tail -2)"
    sleep 2
done
```

## Task 8: Cleanup

```bash
read LOOP1 LOOP2 LOOP3 < ~/practice/raid/loops.txt

sudo umount /mnt/raid_test 2>/dev/null
sudo rmdir /mnt/raid_test 2>/dev/null || true
sudo mdadm --stop /dev/md10 2>/dev/null
sudo losetup -d "$LOOP1" "$LOOP2" "$LOOP3" 2>/dev/null || true
rm -f ~/practice/raid/disk*.img ~/practice/raid/loops.txt
echo "Cleanup done"
```

## Task 9: Write a RAID Health Check Script

```bash
cat > ~/practice/raid/raid_health.sh << 'EOF'
#!/bin/bash
echo "=== Software RAID Health ==="

# Check if any arrays exist
if ! grep -q '^md' /proc/mdstat; then
    echo "No active RAID arrays"
    exit 0
fi

# Parse /proc/mdstat for degraded arrays
awk '
/^md/ {
    name = $1
    gsub(/:/, "", name)
    level = ""
    state = "UNKNOWN"
    for (i=1; i<=NF; i++) {
        if ($i ~ /raid/) level = $i
    }
}
/\[U/ {
    line = $0
    # Count U (up) and _ (failed) characters
    ups = gsub(/U/, "U", line)
    downs = gsub(/_/, "_", line)
    if (downs > 0) {
        print "DEGRADED: " name " (" level ") - " downs " disk(s) failed"
    } else {
        print "OK: " name " (" level ") - all " ups " disk(s) healthy"
    }
}
/resync|recovery|check|repair/ {
    print "REBUILDING: " name " - " $0
}
' /proc/mdstat
EOF
chmod +x ~/practice/raid/raid_health.sh
bash ~/practice/raid/raid_health.sh
```

## Expected Outcome

- `mdadm` is installed and `--version` works
- `/proc/mdstat` is readable and shows RAID personality/array info
- A RAID 1 array is created on loop devices
- Drive failure is simulated, data remains accessible from the mirror
- A replacement disk is added and rebuild begins
- `~/practice/raid/raid_health.sh` reads `/proc/mdstat` and reports degraded arrays
