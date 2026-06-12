# LUKS and dm-crypt — Disk Encryption

LUKS (Linux Unified Key Setup) is the standard for block device encryption on Linux. It sits between the block device and the filesystem, transparently encrypting all data written and decrypting all data read.

## The Encryption Stack

```
Application
    ↓
Filesystem (ext4, xfs, ...)
    ↓
dm-crypt (kernel device mapper target) ← LUKS header lives here
    ↓
Block device (/dev/sdb, /dev/sdb1, loop device, ...)
```

`dm-crypt` is the kernel component. LUKS is the metadata format that dm-crypt uses to store encryption parameters and key material. `cryptsetup` is the userspace tool for managing both.

## LUKS Concepts

- **LUKS header** — stored at the start of the encrypted device; contains cipher, key size, iteration count, and up to 8 key slots
- **Key slots** — each holds a passphrase (or key file) that can unlock the volume. Multiple passphrases can unlock the same device.
- **Master key** — the actual encryption key; never stored directly; each passphrase decrypts a copy of the master key
- **Cipher** — default: `aes-xts-plain64` (AES in XTS mode, the standard for disk encryption)

## cryptsetup — Managing LUKS Volumes

### Creating an Encrypted Volume

```bash
# Create a LUKS container on a device (DESTRUCTIVE — erases all data)
sudo cryptsetup luksFormat /dev/sdb

# With explicit options (stronger KDF)
sudo cryptsetup luksFormat \
    --type luks2 \
    --cipher aes-xts-plain64 \
    --key-size 512 \
    --hash sha256 \
    --iter-time 2000 \
    /dev/sdb

# Create on a file (loop device — safe for practice)
dd if=/dev/urandom of=/tmp/encrypted.img bs=1M count=100
sudo cryptsetup luksFormat /tmp/encrypted.img
```

### Opening and Closing

```bash
# Open (decrypt and create a mapped device)
sudo cryptsetup open /dev/sdb my_encrypted_disk
# Creates /dev/mapper/my_encrypted_disk

# Open from a loop-backed file
LOOP=$(sudo losetup -f --show /tmp/encrypted.img)
sudo cryptsetup open "$LOOP" practice_crypt

# Format the now-accessible plaintext device
sudo mkfs.ext4 /dev/mapper/practice_crypt

# Mount it like any filesystem
sudo mkdir -p /mnt/secure
sudo mount /dev/mapper/practice_crypt /mnt/secure

# Write to it
echo "secret data" | sudo tee /mnt/secure/secret.txt

# Unmount and close (re-encrypts, makes raw device unreadable)
sudo umount /mnt/secure
sudo cryptsetup close practice_crypt
sudo losetup -d "$LOOP"
```

### Inspecting a LUKS Device

```bash
# Show LUKS header information
sudo cryptsetup luksDump /dev/sdb
# Outputs: Version, Cipher, Key size, active Key Slots, etc.

# Check if a device is LUKS-formatted
sudo cryptsetup isLuks /dev/sdb && echo "LUKS formatted" || echo "not LUKS"

# Show the status of an open mapping
sudo cryptsetup status my_encrypted_disk
# type: LUKS2, cipher: aes-xts-plain64, keysize: 512 bits, ...
```

### Managing Key Slots (Passphrases)

```bash
# Add a second passphrase (backup passphrase)
sudo cryptsetup luksAddKey /dev/sdb

# Remove a passphrase (must provide the passphrase to remove)
sudo cryptsetup luksRemoveKey /dev/sdb

# Add a key file (for automated unlocking without a passphrase)
dd if=/dev/urandom of=/etc/luks-keys/mydevice.key bs=4096 count=1
chmod 400 /etc/luks-keys/mydevice.key
sudo cryptsetup luksAddKey /dev/sdb /etc/luks-keys/mydevice.key

# Open using a key file
sudo cryptsetup open /dev/sdb my_encrypted_disk --key-file /etc/luks-keys/mydevice.key
```

## Persistent Mounting with /etc/crypttab and /etc/fstab

```bash
# /etc/crypttab: device → mapper name → key source
# Format: <name> <device> <key-file> <options>
sudo tee /etc/crypttab << 'EOF'
my_disk  /dev/sdb  none  luks         # prompt for passphrase at boot
my_disk2 /dev/sdc  /etc/luks-keys/sdc.key  luks  # auto-unlock with key file
EOF

# /etc/fstab: mount the mapped device
echo '/dev/mapper/my_disk  /mnt/secure  ext4  defaults,noatime  0 2' | sudo tee -a /etc/fstab
```

## Benchmarking Encryption Performance

```bash
# Benchmark available ciphers on this hardware
sudo cryptsetup benchmark

# Output shows encryption/decryption speed for each cipher:
# #  Algorithm | Key |  Encryption |  Decryption
#     aes-xts   256b    1234.5 MiB/s    1198.2 MiB/s
#     aes-xts   512b     897.3 MiB/s     901.4 MiB/s

# Modern x86 CPUs with AES-NI achieve ~GB/s — negligible overhead
```

## LUKS2 and Argon2

LUKS2 (default since cryptsetup 2.0) uses **Argon2** as its KDF (Key Derivation Function) instead of PBKDF2. Argon2 is memory-hard, making brute-force attacks much more expensive.

```bash
# LUKS version of a device
sudo cryptsetup luksDump /dev/sdb | grep Version

# LUKS1: PBKDF2 — fast to test on GPUs
# LUKS2: Argon2id — memory-hard, GPU-resistant
```

## Plain dm-crypt (No LUKS Header)

For maximum deniability: no LUKS header means no way to detect that encryption is in use, but also no key slot management.

```bash
# Open as plain dm-crypt (passphrase must be identical every time — no header to verify)
sudo cryptsetup open --type plain /dev/sdb plain_disk --cipher aes-xts-plain64

# Not recommended for general use — no way to add a second passphrase or verify
```

## Security Considerations

```bash
# After closing, verify the raw device looks random (no plaintext)
sudo hexdump -C /dev/sdb | head -5
# Should show apparently random data — no visible filesystem signatures

# Check for the LUKS magic header
sudo dd if=/dev/sdb bs=6 count=1 2>/dev/null | strings
# Should output "LUKS" followed by version bytes if LUKS-formatted

# Ensure swap is also encrypted (unencrypted swap can leak plaintext)
# /etc/crypttab:
# swap  /dev/sda3  /dev/urandom  swap,cipher=aes-xts-plain64
```

## Further Reading

- [cryptsetup project wiki — DMCrypt](https://gitlab.com/cryptsetup/cryptsetup/-/wikis/DMCrypt) — the official cryptsetup wiki covering dm-crypt modes (plain, LUKS1, LUKS2), benchmarks, and the full `cryptsetup` command reference.
- [LUKS2 on-disk format specification](https://gitlab.com/cryptsetup/LUKS2-docs) — the binary specification for the LUKS2 header: key slot layout, Argon2 KDF parameters, and the JSON metadata area that replaces LUKS1's fixed header.
- [Arch Wiki — dm-crypt/Encrypting a non-root file system](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_a_non-root_file_system) — practical guide to encrypting data partitions: `crypttab` setup, key files for automated unlocking, swap encryption, and loopback-based encrypted containers.
- [dm-crypt — kernel.org](https://www.kernel.org/doc/html/latest/admin-guide/device-mapper/dm-crypt.html) — kernel device-mapper target documentation for `dm-crypt`: parameter syntax, cipher specification format (`aes-xts-plain64`), and IV generation modes.
- [cryptsetup(8) — man7.org](https://man7.org/linux/man-pages/man8/cryptsetup.8.html) — complete `cryptsetup` command reference for `luksFormat`, `open`, `close`, `luksDump`, `luksAddKey`, and the `benchmark` subcommand used in this lesson.
