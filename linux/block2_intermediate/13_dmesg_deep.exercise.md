# Exercise: dmesg — Kernel Ring Buffer

## Tasks

1. **Basic output**: Run `dmesg -T | tail -30` and save to `~/practice/dmesg_recent.txt`. Note what types of messages appear.

2. **Errors only**: Run `dmesg -T -l err,crit,emerg 2>/dev/null | head -20` and save to `~/practice/dmesg_errors.txt`. If empty, write "no errors in ring buffer" to the file.

3. **Hardware events**: Search for network interface messages and USB events:
   ```bash
   dmesg -T | grep -iE "(eth|enp|eno|wlan|usb|link is|tun)" > ~/practice/dmesg_hw.txt
   echo "---" >> ~/practice/dmesg_hw.txt
   dmesg -T | grep -i "EXT4\|xfs\|filesystem" >> ~/practice/dmesg_hw.txt || true
   ```

4. **Write to kernel log**: Write a test message to the kernel ring buffer and verify it appears:
   ```bash
   echo "linux-study: dmesg exercise $(date)" | sudo tee /dev/kmsg 2>/dev/null || \
     echo "write to /dev/kmsg requires root or CAP_SYSLOG" > ~/practice/dmesg_write.txt
   dmesg | tail -5 > ~/practice/dmesg_write.txt
   ```

5. **Compare with journalctl**: Run `journalctl -k --no-pager | tail -10` and save to `~/practice/journalctl_kernel.txt`. Note any differences from `dmesg` output.

## Hints

- `dmesg -l err` may return nothing if there are no errors — that's a good sign
- Writing to `/dev/kmsg` requires `CAP_SYSLOG` — in a container this may require `--privileged`
- `journalctl -k` and `dmesg` show the same kernel messages but with different timestamp formats
