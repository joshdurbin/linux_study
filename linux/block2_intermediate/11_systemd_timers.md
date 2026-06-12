# systemd Timers

systemd timers replace cron for scheduled tasks with better dependency handling, logging, and missed-run recovery.

## Timer vs Service Pair

Every `.timer` unit activates a corresponding `.service` unit with the same name:

```
/etc/systemd/system/backup.timer    ← defines the schedule
/etc/systemd/system/backup.service  ← defines what runs
```

## Timer Unit File

```ini
[Unit]
Description=Daily Database Backup

[Timer]
# Realtime (calendar-based) — like cron
OnCalendar=daily               # every day at midnight
OnCalendar=Mon..Fri 09:00:00   # weekdays at 9am
OnCalendar=*-*-* 02:30:00      # every day at 2:30am
OnCalendar=weekly              # shorthand: Mon 00:00:00

# Monotonic (relative to boot/unit activation)
OnBootSec=5min                 # 5 minutes after boot
OnUnitActiveSec=1h             # 1 hour after last activation
OnActiveSec=30s                # 30 seconds after timer start

# Options
AccuracySec=1s                 # how precisely to fire (default: 1min — saves power)
RandomizedDelaySec=10min       # add random delay to spread load
Persistent=true                # catch missed runs after sleep/shutdown (like anacron)
Unit=backup.service            # explicit if names don't match

[Install]
WantedBy=timers.target
```

## Calendar Expression Syntax

```
minutely          = *-*-* *:*:00
hourly            = *-*-* *:00:00
daily             = *-*-* 00:00:00
weekly            = Mon *-*-* 00:00:00
monthly           = *-*-01 00:00:00
quarterly         = *-01,04,07,10-01 00:00:00
annually / yearly = *-01-01 00:00:00
```

Custom: `2026-06-15 14:30:00`, `Mon,Wed,Fri 18:00`, `*-*-1/2 00:00` (every other day)

Validate a calendar spec:
```bash
systemd-analyze calendar "Mon..Fri 09:00"
```

## Managing Timers

```bash
systemctl list-timers          # all timers: next, last, unit
systemctl list-timers --all    # include inactive
systemctl enable --now backup.timer   # enable and start immediately
systemctl start backup.timer   # run schedule now
systemctl start backup.service # manually trigger the service once
```

## One-Shot Timers with systemd-run

```bash
# Run a command 5 minutes from now
systemd-run --on-active=5min /usr/bin/backup.sh

# Run at a specific calendar time
systemd-run --on-calendar="2026-12-01 03:00" /usr/bin/year-end.sh

# Check transient units
systemctl list-timers --all | grep transient
```

## Advantages Over Cron

| Feature | cron | systemd timer |
|---------|------|---------------|
| Missed run recovery | No (use anacron) | `Persistent=true` |
| Logging | syslog only | full journald integration |
| Dependencies | None | Full unit dependency graph |
| Per-user timers | Limited | `systemctl --user` |
| Sandboxing | None | Full service security options |
| Debugging | Hard | `systemctl status`, `journalctl -u` |

## Further Reading

- [systemd.timer(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.timer.html) — Authoritative reference for every `[Timer]` directive: `OnCalendar=`, `OnBootSec=`, `Persistent=`, `AccuracySec=`, and `RandomizedDelaySec=`.
- [systemd.time(7)](https://www.freedesktop.org/software/systemd/man/latest/systemd.time.html) — The complete grammar for systemd calendar expressions and timespan strings — the reference for writing `OnCalendar=` values correctly.
- [Arch Wiki — systemd/Timers](https://wiki.archlinux.org/title/Systemd/Timers) — Practical guide with worked examples for daily, weekly, and on-boot timers, plus the comparison with cron and `Persistent=true` for missed runs.
- [Arch Wiki — systemd/Timers as cron replacement](https://wiki.archlinux.org/title/Systemd/Timers#As_a_cron_replacement) — Direct comparison table and migration guide for converting common cron patterns to equivalent systemd timer units.
