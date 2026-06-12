# Exercise: The Linux Boot Process

## Tasks

1. **Firmware type**: Determine if the system booted via UEFI or BIOS and examine boot entries:
   ```bash
   {
     echo "=== Firmware Type ==="
     ls /sys/firmware/efi 2>/dev/null && echo "UEFI boot" || echo "BIOS/Legacy boot"
     echo "=== EFI Boot Manager ==="
     efibootmgr 2>/dev/null || echo "efibootmgr not available (BIOS boot or not installed)"
   } > ~/practice/boot_firmware.txt
   ```

2. **Kernel command line**: Examine how the running kernel was booted:
   ```bash
   echo "=== Kernel Cmdline ===" > ~/practice/boot_cmdline.txt
   cat /proc/cmdline >> ~/practice/boot_cmdline.txt
   echo "=== Running Kernel ===" >> ~/practice/boot_cmdline.txt
   uname -r >> ~/practice/boot_cmdline.txt
   echo "=== /boot contents ===" >> ~/practice/boot_cmdline.txt
   ls -lh /boot/ >> ~/practice/boot_cmdline.txt
   ```

3. **GRUB configuration**: Read the GRUB defaults and note the timeout and default cmdline:
   ```bash
   cat /etc/default/grub > ~/practice/boot_grub_defaults.txt 2>/dev/null || \
     echo "No /etc/default/grub (container environment)" > ~/practice/boot_grub_defaults.txt
   ```

4. **initramfs contents**: List the first 30 files in the current initramfs:
   ```bash
   sudo lsinitramfs /boot/initrd.img-$(uname -r) 2>/dev/null | head -30 \
     > ~/practice/boot_initramfs.txt || \
   ls /boot/*.img 2>/dev/null | head -1 | xargs sudo lsinitramfs 2>/dev/null | head -30 \
     > ~/practice/boot_initramfs.txt || \
   echo "initramfs not accessible in this environment" > ~/practice/boot_initramfs.txt
   ```

5. **Boot sequence diagram**: Write `~/practice/boot_sequence.txt` describing the 5-stage boot chain in your own words (firmware → bootloader → kernel → initramfs → init). At least one sentence per stage.

## Hints

- In a Docker container, `/sys/firmware/efi` likely doesn't exist and many boot tools won't work — document what you find, the concepts still apply
- `/proc/cmdline` is always available and shows how the host kernel was actually booted
- `systemd-analyze blame` works even in a container if systemd is PID 1 (not always the case)
