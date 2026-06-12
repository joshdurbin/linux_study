# logrotate — Log File Management

Log files grow indefinitely without management. logrotate compresses, rotates, and expires log files on a schedule, keeping disk usage bounded without losing historical data.

## How It Works

logrotate runs daily (via `/etc/cron.daily/logrotate` or a systemd timer) and processes config files to rotate matching log files. Each run checks if rotation conditions are met (size threshold, time interval) and applies the configured actions.

```bash
# Run logrotate manually (respects state — won't re-rotate until due)
sudo logrotate /etc/logrotate.conf

# Force rotation regardless of schedule
sudo logrotate -f /etc/logrotate.d/nginx

# Dry run — show what would happen without doing it
sudo logrotate -d /etc/logrotate.conf
```

## Configuration Files

```
/etc/logrotate.conf          # global defaults
/etc/logrotate.d/            # per-application configs (drop-ins)
/var/lib/logrotate/status    # state file: last rotation dates
```

## Directive Reference

```
# /etc/logrotate.d/myapp
/var/log/myapp/*.log {
    daily               # rotate every day
    weekly              # or: rotate every week
    monthly             # or: rotate every month
    size 100M           # rotate when file exceeds 100MB (ignores time)

    rotate 14           # keep 14 rotated files before deleting

    compress            # gzip rotated files
    delaycompress       # compress the previous rotation (not the current one)
                        # needed when apps hold the log file open

    missingok           # don't error if log file is missing
    notifempty          # don't rotate if log is empty

    create 0640 www-data adm   # create new log with these perms/owner
    dateext             # use date suffix instead of numbers: .log-2026-06-11
    dateformat -%Y%m%d  # custom date format

    sharedscripts       # run postrotate script once even if multiple logs matched
    postrotate
        nginx -s reopen   # tell nginx to reopen log files
        # or: systemctl kill -s HUP nginx.service
    endscript

    prerotate
        # runs before rotation
    endscript
}
```

## Signal-Based Log Reopening

Most daemons hold log files open by file descriptor. After rotation, the daemon still writes to the old (now-renamed) file until told to reopen:

```bash
# NGINX
nginx -s reopen

# Apache
apachectl graceful

# systemd services (sends USR1 or HUP)
systemctl kill -s USR1 nginx.service

# Generic: send HUP to the process
kill -HUP $(cat /var/run/nginx.pid)
```

## Global Defaults in /etc/logrotate.conf

```
weekly
rotate 4
create
compress
include /etc/logrotate.d    # include all drop-in files
```

## Common Configs

```
# Nginx
/var/log/nginx/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 $(cat /var/run/nginx.pid)
    endscript
}

# Syslog (already managed by rsyslog/syslog)
/var/log/syslog {
    rotate 7
    daily
    missingok
    notifempty
    delaycompress
    compress
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
```

## Checking State

```bash
# When was each log last rotated?
cat /var/lib/logrotate/status | head -20

# List all configs logrotate will process
ls /etc/logrotate.d/

# Verbose dry run (shows every decision)
sudo logrotate -dv /etc/logrotate.conf 2>&1 | head -40
```

## journald vs logrotate

systemd's journal (`/var/log/journal/`) has its own size management:
```bash
journalctl --disk-usage
sudo journalctl --vacuum-size=500M   # reduce journal to 500MB
sudo journalctl --vacuum-time=30d    # remove entries older than 30 days
```

Configure journal size in `/etc/systemd/journald.conf`:
```
SystemMaxUse=1G
SystemKeepFree=100M
MaxRetentionSec=3month
```

## Further Reading

- [man7.org — logrotate(8)](https://man7.org/linux/man-pages/man8/logrotate.8.html) — The full logrotate command reference including `-d` dry-run, `-f` force, and `-v` verbose output for debugging rotation decisions.
- [man7.org — logrotate.conf(5)](https://man7.org/linux/man-pages/man5/logrotate.5.html) — Authoritative specification for every config directive: `compress`, `delaycompress`, `sharedscripts`, `dateext`, `olddir`, and `tabooext`.
- [Arch Wiki — Logrotate](https://wiki.archlinux.org/title/Logrotate) — Practical examples for nginx, Apache, and custom applications, including the `postrotate` signal patterns and the state file format.
- [man7.org — inotify(7)](https://man7.org/linux/man-pages/man7/inotify.7.html) — The kernel event mechanism that logging daemons use to detect rotation; understanding it clarifies why `postrotate` signals are necessary.
- [Debian Reference — System Logs](https://www.debian.org/doc/manuals/debian-reference/ch09.en.html#_log_management) — Covers log management in the Debian ecosystem including syslog, rsyslog, logrotate integration, and retention strategies.
