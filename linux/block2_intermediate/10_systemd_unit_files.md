# systemd Unit Files

Understanding unit file anatomy lets you write, modify, and debug services correctly rather than copy-pasting without knowing what each line does.

## Unit File Locations (precedence, highest first)

```
/etc/systemd/system/        # admin-managed, overrides vendor
/run/systemd/system/        # runtime, cleared on reboot
/lib/systemd/system/        # vendor-shipped (distro packages)
```

`systemctl cat nginx` shows the effective unit including any drop-ins.

## [Unit] Section

```ini
[Unit]
Description=NGINX HTTP Server
Documentation=https://nginx.org/en/docs/
After=network.target        # start after network is up (ordering)
Wants=network.target        # soft dependency (starts it if possible)
Requires=postgresql.service # hard dependency (fails if postgres fails)
BindsTo=postgresql.service  # stops this unit if postgres stops
Conflicts=apache2.service   # cannot run at the same time
```

`After`/`Before` = ordering. `Wants`/`Requires` = dependency. They're independent — you almost always use both together.

## [Service] Section

```ini
[Service]
Type=simple         # exec'd process IS the service (default)
# Type=forking      # process forks; parent exits; use PIDFile=
# Type=oneshot      # runs to completion; ExecStart exits cleanly
# Type=notify       # process calls sd_notify() when ready
# Type=dbus         # ready when it acquires a D-Bus name

ExecStartPre=/usr/bin/nginx -t          # run before start (test config)
ExecStart=/usr/sbin/nginx               # main process
ExecReload=/bin/kill -HUP $MAINPID      # config reload signal
ExecStop=/usr/sbin/nginx -s quit        # graceful stop

Restart=on-failure      # restart if exits non-zero or by signal
# Restart=always        # always restart
# Restart=on-abnormal   # restart on signal, watchdog timeout, or bus error
RestartSec=5s

User=www-data           # run as this user
Group=www-data
WorkingDirectory=/var/www/html

Environment=NODE_ENV=production         # inline env var
EnvironmentFile=/etc/nginx/env          # env vars from file (KEY=VALUE)

# Resource limits
LimitNOFILE=65536           # equivalent to ulimit -n
MemoryMax=512M              # cgroup memory limit
CPUQuota=50%                # max 50% of one CPU

# Security hardening
NoNewPrivileges=yes
ProtectSystem=strict
PrivateTmp=yes
```

## [Install] Section

```ini
[Install]
WantedBy=multi-user.target   # symlinked into multi-user.target.wants/ on enable
# WantedBy=graphical.target
# RequiredBy=some.target
Alias=httpd.service          # also accessible under this name
Also=nginx-helper.service    # enable this unit too when enabling nginx
```

`systemctl enable` creates the symlinks from this section. Without [Install], the unit can be started manually but not enabled.

## Drop-in Overrides

Never edit `/lib/systemd/system/` directly — it gets overwritten on package upgrades.

```bash
# Interactive: creates /etc/systemd/system/nginx.service.d/override.conf
sudo systemctl edit nginx

# Manual: create the directory and file yourself
sudo mkdir -p /etc/systemd/system/nginx.service.d/
sudo tee /etc/systemd/system/nginx.service.d/memory.conf << 'EOF'
[Service]
MemoryMax=256M
EOF

sudo systemctl daemon-reload
sudo systemctl restart nginx
```

## Inspecting Units

```bash
systemctl cat nginx              # show effective unit + drop-ins
systemctl show nginx             # all properties (machine-readable)
systemctl show nginx --property=Restart,RestartSec
systemd-analyze verify /etc/systemd/system/myapp.service  # lint
```

## Further Reading

- [systemd.unit(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html) — Authoritative reference for every `[Unit]` directive including `After=`, `Wants=`, `Requires=`, `PartOf=`, and specifier variables like `%i` and `%H`.
- [systemd.service(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html) — Complete `[Service]` reference: all `Type=` values, `ExecStart`/`ExecReload`/`ExecStop`, `Restart=` policies, and `EnvironmentFile=`.
- [systemd.exec(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html) — Documents execution environment directives: `User=`, `CapabilityBoundingSet=`, `ProtectSystem=`, `SystemCallFilter=`, and all sandboxing options.
- [Arch Wiki — Writing unit files](https://wiki.archlinux.org/title/Systemd#Writing_unit_files) — Practical guide to writing and debugging unit files, drop-in overrides, and common patterns for web servers and daemons.
- [systemd.io — Generators](https://systemd.io/GENERATORS/) — Explains how systemd generators dynamically create unit files at boot, useful context for understanding `/run/systemd/generator/` units.
