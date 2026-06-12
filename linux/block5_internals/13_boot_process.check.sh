#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "boot_firmware.txt exists"          "[[ -f ~/practice/boot_firmware.txt ]]"
check "boot_firmware.txt has firmware type" "grep -qiE '(UEFI|BIOS|legacy)' ~/practice/boot_firmware.txt"
check "boot_cmdline.txt exists"           "[[ -f ~/practice/boot_cmdline.txt ]]"
check "boot_cmdline.txt has kernel version" "grep -qE '[0-9]+\.[0-9]+\.[0-9]+' ~/practice/boot_cmdline.txt"
check "boot_grub_defaults.txt exists"     "[[ -f ~/practice/boot_grub_defaults.txt ]]"
check "boot_initramfs.txt exists"         "[[ -f ~/practice/boot_initramfs.txt ]]"
check "boot_sequence.txt exists"          "[[ -f ~/practice/boot_sequence.txt ]]"
check "boot_sequence.txt has 5+ lines"    "[[ $(wc -l < ~/practice/boot_sequence.txt) -ge 5 ]]"
check "boot_sequence.txt mentions kernel" "grep -qi 'kernel' ~/practice/boot_sequence.txt"
check "boot_sequence.txt mentions init or systemd" "grep -qiE '(init|systemd)' ~/practice/boot_sequence.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
