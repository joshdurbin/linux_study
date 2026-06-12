# The Linux Boot Process

Understanding the boot chain — from power-on to your shell prompt — is essential for diagnosing boot failures, configuring kernel parameters, and understanding how services come up.

## The Full Chain

```
Power on
  └── Firmware (BIOS or UEFI)
        └── Bootloader (GRUB2)
              └── Kernel (vmlinuz)
                    └── initramfs (temporary root)
                          └── real root filesystem mounted
                                └── init system (systemd, PID 1)
                                      └── targets, services, getty
                                            └── login prompt
```

## Stage 1: Firmware — BIOS vs UEFI

**BIOS (legacy):**
- Reads MBR (first 512 bytes of disk) — contains GRUB stage 1
- Limited to 2TB disks (MBR partition table)
- Boot order set in CMOS

**UEFI (modern):**
- Reads the EFI System Partition (ESP, FAT32, typically `/boot/efi`)
- Boots EFI applications directly (GRUB is an EFI app: `grubx64.efi`)
- Supports 8ZB disks (GPT partition table)
- Secure Boot: verifies bootloader signature

```bash
# Check if booted via UEFI
ls /sys/firmware/efi && echo "UEFI" || echo "BIOS/Legacy"

# List UEFI boot entries
efibootmgr -v

# EFI System Partition
ls /boot/efi/EFI/
```

## Stage 2: GRUB2

GRUB2 presents the boot menu and loads the kernel.

```bash
# Main config (auto-generated, do not edit directly)
cat /boot/grub/grub.cfg | head -40

# User-editable settings
cat /etc/default/grub

# Per-menu-entry scripts
ls /etc/grub.d/

# Regenerate grub.cfg after changes
sudo update-grub          # Debian/Ubuntu
sudo grub2-mkconfig -o /boot/grub2/grub.cfg  # RHEL/Fedora
```

Key `/etc/default/grub` settings:
```bash
GRUB_DEFAULT=0             # default menu entry (0=first)
GRUB_TIMEOUT=5             # seconds to show menu
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"  # kernel params for normal boot
GRUB_CMDLINE_LINUX=""      # kernel params for ALL boots (including recovery)
```

### Kernel Parameters

Passed on the kernel command line, visible in `/proc/cmdline`:

```bash
cat /proc/cmdline
# BOOT_IMAGE=/vmlinuz-6.8.0-40-generic root=UUID=... ro quiet splash

# Common parameters:
# ro/rw          — mount root read-only or read-write initially
# root=           — root device (UUID, /dev/sdX, or LABEL=)
# init=/bin/bash  — use bash as PID 1 (emergency recovery)
# single / 1      — boot to single-user mode
# console=ttyS0   — serial console
# nomodeset       — disable GPU kernel mode setting (graphics issues)
# rd.break        — break into initramfs shell (systemd)
```

## Stage 3: Kernel

```bash
# Kernel and initramfs files
ls -lh /boot/
# vmlinuz-VERSION    — compressed kernel image
# initrd.img-VERSION — initramfs archive
# System.map-VERSION — kernel symbol table

# Which kernel is running?
uname -r
uname -a
```

## Stage 4: initramfs

A temporary root filesystem (a cpio archive) extracted into RAM. It contains drivers needed to mount the real root:

```bash
# List contents of the initramfs
sudo lsinitramfs /boot/initrd.img-$(uname -r) | head -30
# or
sudo unmkinitramfs /boot/initrd.img-$(uname -r) /tmp/initrd-contents

# Rebuild initramfs (after adding drivers or changing config)
sudo update-initramfs -u -k all   # Debian/Ubuntu
sudo dracut --force                # RHEL/Fedora
```

Key jobs of initramfs:
1. Load storage and filesystem drivers
2. Assemble software RAID / LVM if needed
3. Decrypt encrypted root (LUKS)
4. `pivot_root` or `switch_root` to the real filesystem
5. Exec `/sbin/init` (systemd)

## Stage 5: systemd

PID 1. Reads unit files, activates targets, starts services.

```bash
# Boot performance analysis
systemd-analyze                     # total time
systemd-analyze blame | head -15    # slowest units
systemd-analyze critical-chain      # critical path
```

## GRUB Recovery

```bash
# Drop to GRUB command line: press 'c' at GRUB menu
grub> ls                    # list devices and partitions
grub> ls (hd0,gpt2)/        # list files on partition
grub> set root=(hd0,gpt2)
grub> linux /boot/vmlinuz root=/dev/sda2
grub> initrd /boot/initrd.img
grub> boot

# Single-user mode: at GRUB, edit the linux line, add 'single' or 'init=/bin/bash'
```

## Further Reading

- [linux-insides — Booting](https://0xax.gitbooks.io/linux-insides/content/Booting/) — covers every boot stage in detail: the real-mode kernel header, protected mode switch, decompression, early page table setup, and the transition to `start_kernel`.
- [systemd boot process — freedesktop.org](https://www.freedesktop.org/software/systemd/man/latest/bootup.html) — systemd's documentation of the full boot sequence from PID 1 startup through target activation, showing how `basic.target`, `sysinit.target`, and `multi-user.target` relate.
- [GRUB2 manual](https://www.gnu.org/software/grub/manual/grub/grub.html) — official GRUB2 reference covering `grub.cfg` syntax, environment variables, recovery commands (`ls`, `linux`, `initrd`, `boot`), UEFI Secure Boot configuration, and the `grub-install` process.
- [kernel.org — Init documentation](https://www.kernel.org/doc/html/latest/admin-guide/init.html) — kernel's own documentation on the init process: how the kernel selects PID 1 from `init=`, `rdinit=`, and fallback paths, and the meaning of kernel panic on init failure.
- [systemd-analyze(1) — freedesktop.org](https://www.freedesktop.org/software/systemd/man/latest/systemd-analyze.html) — documents the `blame`, `critical-chain`, `plot`, and `dot` subcommands used to diagnose and optimize slow boot sequences.
