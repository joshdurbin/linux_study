# systemd Services

systemd is the init system and service manager on modern Linux. It manages services (daemons), mounts, timers, and more. `systemctl` is the primary control interface; `journalctl` reads the logs.

## systemctl — Service Control

### Checking Service Status

```bash
systemctl status nginx             # detailed status + recent logs
systemctl status nginx.service     # same (unit suffix optional)
systemctl is-active nginx          # prints "active" or "inactive"
systemctl is-enabled nginx         # prints "enabled" or "disabled"
systemctl is-failed nginx          # check if failed
```

### Starting and Stopping

```bash
sudo systemctl start nginx         # start now (does not survive reboot)
sudo systemctl stop nginx          # stop now
sudo systemctl restart nginx       # stop then start
sudo systemctl reload nginx        # reload config without restart (if supported)
sudo systemctl reload-or-restart nginx  # reload if supported, else restart
sudo systemctl try-restart nginx   # restart only if already running
```

### Enable / Disable (survive reboots)

```bash
sudo systemctl enable nginx        # start at boot
sudo systemctl disable nginx       # do not start at boot
sudo systemctl enable --now nginx  # enable AND start immediately
sudo systemctl disable --now nginx # disable AND stop immediately
```

### Listing Services

```bash
systemctl list-units               # all active units
systemctl list-units --type=service  # services only
systemctl list-units --state=failed  # failed units
systemctl list-unit-files          # all installed units + enabled status
systemctl list-unit-files --type=service
```

### System State

```bash
systemctl daemon-reload            # reload unit files after editing
sudo systemctl reboot              # reboot
sudo systemctl poweroff            # shut down
sudo systemctl suspend             # suspend
systemctl get-default              # current target (e.g., multi-user.target)
```

## journalctl — View Logs

systemd captures all service output in the journal (binary log).

```bash
journalctl                         # all journal entries (oldest first)
journalctl -r                      # reverse (newest first)
journalctl -n 50                   # last 50 lines
journalctl -f                      # follow: stream new entries
journalctl -u nginx                # logs for nginx service only
journalctl -u nginx -f             # follow nginx logs
journalctl -u nginx -n 100         # last 100 nginx log lines
journalctl -u nginx --since "1 hour ago"
journalctl -u nginx --since "2024-01-01" --until "2024-01-02"
journalctl -p err                  # only error-level and above
journalctl -p warning..err         # warning through error
journalctl -k                      # kernel messages only (like dmesg)
journalctl -b                      # since last boot
journalctl -b -1                   # previous boot
journalctl --disk-usage            # how much disk the journal uses
```

## Unit Files

Service unit files live in:
- `/lib/systemd/system/` — package-provided (do not edit)
- `/etc/systemd/system/` — local overrides and custom units

```bash
systemctl cat nginx.service        # view the unit file
systemctl edit nginx.service       # create an override (drop-in)
```

Minimal service unit:
```ini
[Unit]
Description=My Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/myapp --config /etc/myapp.conf
Restart=on-failure
User=myapp

[Install]
WantedBy=multi-user.target
```

Place in `/etc/systemd/system/myapp.service`, then:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now myapp
```

## Common Patterns

```bash
# Check all failed services
systemctl --failed

# Restart and watch logs
sudo systemctl restart nginx && journalctl -u nginx -f -n 20

# View startup time for each service
systemd-analyze blame

# Check total boot time
systemd-analyze
```

## Further Reading

- [systemd.io](https://systemd.io/) — The official systemd project site with news, documentation index, and links to all man pages.
- [systemd.service(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html) — The authoritative reference for every `[Service]` directive: `Type=`, `Restart=`, `ExecStart`, `EnvironmentFile`, and security options.
- [journalctl(1)](https://www.freedesktop.org/software/systemd/man/latest/journalctl.html) — Full journalctl flag reference including `--output=json`, `--catalog`, `--vacuum-size`, and field matching syntax (`_SYSTEMD_UNIT=`).
- [Arch Wiki — systemd](https://wiki.archlinux.org/title/Systemd) — Practical guide covering unit management, drop-in overrides, targets, and troubleshooting failed services.
- [man7.org — systemd.unit(5)](https://man7.org/linux/man-pages/man5/systemd.unit.5.html) — Documents the `[Unit]` section directives: `After=`, `Wants=`, `Requires=`, `BindsTo=`, and `PartOf=` dependency semantics.
