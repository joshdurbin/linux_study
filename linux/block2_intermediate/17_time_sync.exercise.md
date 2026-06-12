# Exercise: Time Synchronization

## Tasks

1. **Check current time state**: Examine all aspects of system time:
   ```bash
   {
     echo "=== timedatectl ==="
     timedatectl
     echo "=== timezone file ==="
     cat /etc/timezone 2>/dev/null || readlink /etc/localtime
     echo "=== hwclock ==="
     sudo hwclock --show 2>/dev/null || echo "hwclock not available"
   } > ~/practice/time_status.txt
   ```

2. **NTP sync status**: Check which NTP daemon is running and its sync state:
   ```bash
   {
     echo "=== NTP service ==="
     systemctl status chronyd 2>/dev/null || systemctl status systemd-timesyncd 2>/dev/null || echo "no NTP service found"
     echo "=== chronyc tracking ==="
     chronyc tracking 2>/dev/null || timedatectl show-timesync 2>/dev/null || echo "chrony not available"
     echo "=== sources ==="
     chronyc sources 2>/dev/null || echo "no sources"
   } > ~/practice/time_ntp.txt
   ```

3. **Timezone change**: Change the timezone to UTC, verify, then change back:
   ```bash
   ORIG_TZ=$(cat /etc/timezone 2>/dev/null || timedatectl | grep "Time zone" | awk '{print $3}')
   sudo timedatectl set-timezone UTC
   echo "After set to UTC: $(date)" > ~/practice/time_tz_test.txt
   sudo timedatectl set-timezone "$ORIG_TZ" 2>/dev/null || sudo timedatectl set-timezone America/New_York
   echo "After restore: $(date)" >> ~/practice/time_tz_test.txt
   echo "Timezone restored to: $(timedatectl | grep 'Time zone')" >> ~/practice/time_tz_test.txt
   ```

4. **chrony config**: Write `~/practice/chrony_config_example.conf` — a valid `/etc/chrony.conf` for a server that:
   - Uses pool.ntp.org as its time source (with iburst)
   - Acts as an NTP server for the 192.168.1.0/24 subnet
   - Has `makestep 1.0 3` for fast initial correction
   - Has a driftfile

5. **Stratum knowledge**: Write `~/practice/ntp_concepts.txt` explaining in your own words: what stratum means, why time sync matters for TLS, and the difference between chrony and systemd-timesyncd.

## Hints

- `timedatectl` is the one-stop command for everything time-related on systemd systems
- `chronyc tracking` shows "System time" (current offset from NTP) and "Frequency" (drift in ppm)
- `makestep` lets chrony make large instant corrections on startup — without it, it adjusts slowly
