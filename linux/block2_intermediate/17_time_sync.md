# Time Synchronization — chrony, NTP, and timedatectl

Accurate time is critical: TLS certificates validate against system time, distributed logs require synchronized clocks, Kerberos auth fails if clocks drift beyond 5 minutes, and database transactions depend on monotonic ordering.

## timedatectl — System Time Management

```bash
timedatectl                         # full status: local time, UTC, RTC, NTP sync
timedatectl status                  # same

timedatectl set-timezone UTC
timedatectl set-timezone America/New_York
timedatectl list-timezones | grep America

timedatectl set-ntp true            # enable NTP sync
timedatectl set-ntp false           # disable (manual time)

timedatectl set-time "2026-06-11 14:30:00"  # only when NTP disabled

# Check sync status
timedatectl show --property=NTPSynchronized
```

## NTP Concepts

- **Stratum**: distance from reference clock. Stratum 0 = atomic/GPS clock. Stratum 1 = directly connected to stratum 0. Stratum 2 syncs from stratum 1, etc.
- **Offset**: difference between local clock and NTP server
- **Jitter**: variability in round-trip time to NTP server
- **Drift**: systematic rate of clock error (ppm = parts per million)
- **Reference clocks**: pool.ntp.org, time.cloudflare.com, time.google.com

## chrony — Modern NTP Implementation

chrony is the default NTP implementation on RHEL 7+, Ubuntu 20.04+. It converges faster than ntpd and handles intermittent connectivity.

```bash
# Status
chronyc tracking                    # current sync status (offset, drift, stratum)
chronyc sources -v                  # all configured time sources
chronyc sourcestats -v              # statistics per source
chronyc ntpdata                     # detailed NTP data

# Drift and correction
chronyc tracking | grep -E "(Offset|RMS|Freq)"

# Force immediate sync (large initial correction)
sudo chronyc makestep

# Check if chrony is running
systemctl status chronyd
```

### /etc/chrony.conf

```conf
# NTP servers (use pool for automatic server selection)
pool 2.ubuntu.pool.ntp.org iburst

# Hardware timestamping (if supported)
# hwtimestamp eth0

# Allow NTP on this subnet (act as NTP server)
# allow 192.168.0/24

# Adjust for large initial drift
makestep 1.0 3

# Record drift to survive reboots
driftfile /var/lib/chrony/drift

# Log directory
logdir /var/log/chrony
```

```bash
sudo systemctl restart chronyd
sudo chronyc makestep               # force immediate correction after config change
```

## systemd-timesyncd — Lightweight SNTP Client

The default on desktop Ubuntu/Debian. Simpler than chrony — one server, basic sync:

```bash
systemctl status systemd-timesyncd
timedatectl show-timesync            # NTP server, polling interval, last sync

# Config: /etc/systemd/timesyncd.conf
# [Time]
# NTP=time.cloudflare.com ntp.ubuntu.com
# FallbackNTP=ntp.ubuntu.com
```

systemd-timesyncd vs chrony: use chrony for servers, VMs with live migration, or anything needing accurate time. timesyncd is sufficient for desktops.

## Hardware Clock (RTC)

```bash
hwclock --show                      # hardware clock time
hwclock --systohc                   # sync hardware clock FROM system time
hwclock --hctosys                   # sync system time FROM hardware clock
hwclock --set --date "2026-06-11 12:00:00"

# /etc/adjtime tracks drift correction:
cat /etc/adjtime
```

## Timezone Files

```bash
# Current timezone
cat /etc/timezone
readlink /etc/localtime             # → /usr/share/zoneinfo/America/New_York

# Change timezone (the modern way)
sudo timedatectl set-timezone Europe/London

# Legacy way
sudo ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Available timezones
ls /usr/share/zoneinfo/
```

## Diagnosing Time Problems

```bash
# Is NTP running and synced?
timedatectl | grep -E "(NTP|Sync)"

# Check offset to a specific server
chronyc ntpdata pool.ntp.org

# Direct NTP query
ntpdate -q pool.ntp.org 2>/dev/null || \
  sntp -q pool.ntp.org 2>/dev/null

# Firewall: NTP uses UDP port 123
ss -uln | grep 123
```

## Further Reading

- [RFC 5905 — Network Time Protocol Version 4](https://datatracker.ietf.org/doc/html/rfc5905) — The IETF specification for NTPv4: packet format, stratum hierarchy, clock filter algorithm, and the reference implementation.
- [chrony Documentation](https://chrony-project.org/documentation.html) — The official chrony reference manual covering `chrony.conf` directives, `chronyc` commands, hardware timestamping, and leap-second handling.
- [timedatectl(1)](https://www.freedesktop.org/software/systemd/man/latest/timedatectl.html) — Full reference for `timedatectl` subcommands including `show`, `show-timesync`, `set-ntp`, and the NTP synchronization status properties.
- [man7.org — hwclock(8)](https://man7.org/linux/man-pages/man8/hwclock.8.html) — Documents RTC read/write modes, `/etc/adjtime` drift correction, and why `--systohc` should run at shutdown.
- [Arch Wiki — System time](https://wiki.archlinux.org/title/System_time) — Comprehensive guide to timezones, RTC mode, NTP, chrony, and systemd-timesyncd with troubleshooting steps for clock drift.
