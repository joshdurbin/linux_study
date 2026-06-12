# Exercise: LUKS Disk Encryption

## Setup

```bash
mkdir -p ~/practice/luks
sudo apt-get install -y cryptsetup 2>/dev/null || true
```

## Task 1: Check cryptsetup is Available

```bash
cryptsetup --version
sudo cryptsetup benchmark 2>/dev/null | head -10 || echo "Benchmark requires root"
```

## Task 2: Create a LUKS Container on a File

```bash
# Create a 64MB file to encrypt (using /dev/urandom for random data)
dd if=/dev/urandom of=~/practice/luks/container.img bs=1M count=64 status=progress
ls -lh ~/practice/luks/container.img

# Format it as LUKS2
# You will be prompted for a passphrase — use something simple like: testpass123
sudo cryptsetup luksFormat --type luks2 ~/practice/luks/container.img
```

## Task 3: Inspect the LUKS Header

```bash
sudo cryptsetup luksDump ~/practice/luks/container.img
```

Note the: Version, Cipher name, Cipher mode, Key size, active Key Slots.

## Task 4: Verify It's LUKS Formatted

```bash
sudo cryptsetup isLuks ~/practice/luks/container.img && \
    echo "Confirmed: LUKS formatted" || echo "Not LUKS"

# The first 6 bytes should contain the LUKS magic
sudo dd if=~/practice/luks/container.img bs=6 count=1 2>/dev/null | xxd
# Should show: 4c55 4b53 babe (LUKS magic bytes)
```

## Task 5: Open, Format, Mount, and Use

```bash
# Set up a loop device
LOOP=$(sudo losetup -f --show ~/practice/luks/container.img)
echo "Loop device: $LOOP"

# Open the LUKS container (enter the passphrase you set in Task 2)
sudo cryptsetup open "$LOOP" practice_luks

# Verify the mapped device exists
ls -la /dev/mapper/practice_luks
sudo cryptsetup status practice_luks

# Format the plaintext device
sudo mkfs.ext4 /dev/mapper/practice_luks

# Mount and write data
sudo mkdir -p /mnt/luks_test
sudo mount /dev/mapper/practice_luks /mnt/luks_test

echo "Secret data written at $(date)" | sudo tee /mnt/luks_test/secret.txt
ls -la /mnt/luks_test/
```

## Task 6: Verify Data is Encrypted on the Raw Device

```bash
# The raw device should look like random noise — no filesystem signatures
echo "Searching for 'Secret' in raw encrypted device (should find nothing):"
sudo grep -c "Secret" "$LOOP" 2>/dev/null || echo "Not found — data is encrypted"

echo "First 64 bytes of raw device (should look random):"
sudo hexdump -C "$LOOP" | head -4
```

## Task 7: Close and Reopen

```bash
# Unmount and close
sudo umount /mnt/luks_test
sudo cryptsetup close practice_luks
sudo losetup -d "$LOOP"

echo "Container closed. Reopening..."

# Reopen (passphrase required again)
LOOP=$(sudo losetup -f --show ~/practice/luks/container.img)
sudo cryptsetup open "$LOOP" practice_luks2

sudo mount /dev/mapper/practice_luks2 /mnt/luks_test
echo "Data after reopen:"
cat /mnt/luks_test/secret.txt

# Full cleanup
sudo umount /mnt/luks_test
sudo cryptsetup close practice_luks2
sudo losetup -d "$LOOP"
sudo rmdir /mnt/luks_test 2>/dev/null || true
```

## Task 8: Write a LUKS Status Script

```bash
cat > ~/practice/luks/luks_status.sh << 'EOF'
#!/bin/bash
echo "=== LUKS Status ==="
echo "cryptsetup version: $(cryptsetup --version 2>/dev/null)"
echo ""

echo "Open LUKS mappings (/dev/mapper/):"
for dm in /dev/mapper/*; do
    [ "$dm" = "/dev/mapper/control" ] && continue
    if sudo cryptsetup status "$(basename $dm)" 2>/dev/null | grep -q "type.*LUKS"; then
        echo "  $dm (LUKS)"
        sudo cryptsetup status "$(basename $dm)" 2>/dev/null | grep -E "cipher|keysize|device"
    fi
done

echo ""
echo "LUKS-formatted block devices:"
for dev in /dev/sd? /dev/nvme?n? /dev/loop?; do
    [ -b "$dev" ] && sudo cryptsetup isLuks "$dev" 2>/dev/null && echo "  $dev"
done

echo ""
echo "Container file:"
ls -lh ~/practice/luks/container.img 2>/dev/null
EOF
chmod +x ~/practice/luks/luks_status.sh
bash ~/practice/luks/luks_status.sh
```

## Expected Outcome

- `cryptsetup` is installed and `--version` works
- `container.img` is created and LUKS-formatted
- `cryptsetup luksDump` shows LUKS2 header with cipher and key slot info
- Data written through the LUKS mapping is not visible as plaintext in the raw device
- Container can be closed and reopened with the same passphrase
- `luks_status.sh` lists open LUKS mappings and detected LUKS devices
