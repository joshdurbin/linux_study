# cron — Task Scheduling

cron runs commands on a schedule. It predates systemd timers and is still widely used for simple recurring tasks. Understanding both helps you choose the right tool and read existing configs.

## crontab Syntax

```
# ┌─ minute      (0-59)
# │ ┌─ hour       (0-23)
# │ │ ┌─ day of month (1-31)
# │ │ │ ┌─ month   (1-12 or jan-dec)
# │ │ │ │ ┌─ day of week (0-7; both 0 and 7 = Sunday, or mon-sun)
# │ │ │ │ │
# * * * * *  command to run
```

### Field Values

```
*        any value
5        exactly 5
1,3,5    1, 3, or 5
1-5      1 through 5 (inclusive)
*/15     every 15 (0, 15, 30, 45)
1-30/2   every 2 from 1 to 30
```

### Examples

```
# Every minute
* * * * *  /usr/bin/check.sh

# Every 5 minutes
*/5 * * * *  /usr/bin/poll.sh

# Daily at 2:30am
30 2 * * *  /usr/bin/backup.sh

# Weekdays at 9am
0 9 * * 1-5  /usr/bin/report.sh

# First day of every month at midnight
0 0 1 * *  /usr/bin/monthly.sh

# Every Sunday at 3am
0 3 * * 0  /usr/bin/weekly.sh

# Every 6 hours
0 */6 * * *  /usr/bin/sync.sh
```

### Special Strings

```
@reboot     once at startup (after cron daemon starts)
@hourly     0 * * * *
@daily      0 0 * * *
@weekly     0 0 * * 0
@monthly    0 0 1 * *
@yearly     0 0 1 1 *
```

## Managing User Crontabs

```bash
crontab -e        # edit your crontab (uses $EDITOR)
crontab -l        # list your crontab
crontab -r        # remove your entire crontab (careful!)
crontab -u alice -l  # list alice's crontab (root only)
```

Crontabs are stored in `/var/spool/cron/crontabs/<username>`.

## System Cron

```bash
/etc/crontab          # system-wide crontab (has extra 'user' field)
/etc/cron.d/          # drop-in cron files (same format as /etc/crontab)
/etc/cron.hourly/     # scripts run every hour by run-parts
/etc/cron.daily/      # scripts run daily
/etc/cron.weekly/
/etc/cron.monthly/
```

Format of `/etc/crontab` and `/etc/cron.d/` files adds a **user** field:
```
# minute hour dom month dow  USER  command
*/5 * * * *  root  /usr/bin/cleanup.sh
0 2 * * *    www-data  /var/www/backup.sh
```

## Environment in Cron

cron runs with a minimal environment — **not** your login shell. This causes most cron failures.

```
# Set environment at the top of your crontab
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
MAILTO=ops@example.com    # email output here (empty = discard)
HOME=/home/alice
```

**Always use absolute paths in cron commands.**

## Capturing Output

```bash
# Discard all output
* * * * *  /usr/bin/script.sh > /dev/null 2>&1

# Log stdout and stderr
* * * * *  /usr/bin/script.sh >> /var/log/myjob.log 2>&1

# Log with timestamp
* * * * *  date >> /var/log/myjob.log && /usr/bin/script.sh >> /var/log/myjob.log 2>&1
```

## Debugging

```bash
# Check cron daemon logs
journalctl -u cron -f
grep CRON /var/log/syslog | tail -20

# Test cron environment (write env to a file)
* * * * *  env > /tmp/cron_env.txt

# Verify cron is running
systemctl status cron
```

## cron vs systemd timers

| Feature | cron | systemd timer |
|---------|------|--------------|
| Config format | `* * * * *` | `OnCalendar=` |
| Missed run recovery | No (use anacron) | `Persistent=true` |
| Logging | syslog only | Full journald |
| Dependencies | None | Full unit graph |
| User timers | Limited | `systemctl --user` |
| Debugging | Hard | `systemctl status`, `journalctl` |

For new work on systemd systems: prefer systemd timers. For existing cron, understand and maintain it.

## Further Reading

- [man7.org — crontab(5)](https://man7.org/linux/man-pages/man5/crontab.5.html) — Authoritative specification for the crontab field syntax, special strings (`@daily`, `@reboot`), `MAILTO`, and `SHELL` variables.
- [man7.org — cron(8)](https://man7.org/linux/man-pages/man8/cron.8.html) — Documents the cron daemon: how it scans crontabs, processes `/etc/cron.d/`, the `CRONPATH` search, and syslog output.
- [Arch Wiki — systemd/Timers — As a cron replacement](https://wiki.archlinux.org/title/Systemd/Timers#As_a_cron_replacement) — Side-by-side comparison of cron syntax and systemd timer equivalents, helping you migrate existing crontabs.
- [man7.org — anacron(8)](https://man7.org/linux/man-pages/man8/anacron.8.html) — Documents anacron's mechanism for running missed daily/weekly/monthly jobs — the traditional answer to cron's lack of `Persistent=true`.
