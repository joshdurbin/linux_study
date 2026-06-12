# systemd: Analyze, Socket Activation, and Advanced Patterns

## systemd-analyze: Boot Performance

```bash
systemd-analyze                    # total boot time: firmware + loader + kernel + userspace
systemd-analyze blame              # each unit's startup time, slowest first
systemd-analyze critical-chain     # critical path through the boot dependency graph
systemd-analyze critical-chain nginx.service  # path to a specific unit
systemd-analyze plot > /tmp/boot.svg  # SVG visualization of the entire boot timeline
systemd-analyze verify myapp.service  # lint a unit file for errors
```

Typical output of `systemd-analyze`:
```
Startup finished in 3.982s (kernel) + 12.703s (userspace) = 16.686s
graphical.target reached after 12.698s in userspace
```

## Socket Activation

The socket is created by systemd; the service is started only when the first connection arrives. Enables on-demand startup and zero-downtime restarts.

**sshd.socket** (example):
```ini
# sshd.socket
[Unit]
Description=OpenSSH Server Socket (systemd socket activation)

[Socket]
ListenStream=22
Accept=yes        # spawn sshd@.service per connection (inetd mode)
# Accept=no       # pass socket fd to a single persistent sshd

[Install]
WantedBy=sockets.target
```

```ini
# sshd@.service (instantiated per-connection when Accept=yes)
[Service]
ExecStart=-/usr/sbin/sshd -i
StandardInput=socket
```

Check what sockets systemd is listening on:
```bash
systemctl list-sockets
```

## Instantiated Units (`@`)

A template unit `foo@.service` can spawn `foo@bar.service`, `foo@baz.service`, etc.

```ini
# /etc/systemd/system/worker@.service
[Unit]
Description=Worker instance %i    # %i = instance name

[Service]
ExecStart=/usr/bin/worker --id=%i --config=/etc/worker/%i.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
systemctl start worker@primary.service
systemctl start worker@secondary.service
systemctl enable worker@primary.service
```

Specifier variables: `%i` (instance name), `%n` (full unit name), `%u` (user), `%H` (hostname).

## User Units

Each user gets their own systemd instance at login:

```bash
systemctl --user status
systemctl --user enable --now myapp.service
journalctl --user -u myapp.service

# Unit files live in:
~/.config/systemd/user/
/usr/lib/systemd/user/
```

Enable lingering (keep user units running after logout):
```bash
sudo loginctl enable-linger $USER
```

## journalctl Advanced

```bash
journalctl -u nginx                   # logs for a specific unit
journalctl -u nginx -f                # follow (like tail -f)
journalctl -u nginx --since "1 hour ago"
journalctl -u nginx --since "2026-06-01" --until "2026-06-02"
journalctl -p err -u nginx            # priority: emerg/alert/crit/err/warning/notice/info/debug
journalctl --disk-usage               # how much space journal uses
journalctl --vacuum-size=500M         # trim to 500MB
journalctl -b                         # current boot only
journalctl -b -1                      # previous boot
journalctl -k                         # kernel messages only (like dmesg)
journalctl -o json | jq '.MESSAGE'    # JSON output for structured queries
```

## Targets (Runlevels)

```bash
systemctl list-units --type=target --all   # all targets
systemctl get-default                       # current default target
systemctl set-default multi-user.target    # no GUI on next boot
systemctl isolate rescue.target             # switch to single-user now
```

| Target | Old runlevel |
|--------|-------------|
| poweroff.target | 0 |
| rescue.target | 1 |
| multi-user.target | 3 |
| graphical.target | 5 |
| reboot.target | 6 |

## Further Reading

- [systemd-analyze(1)](https://www.freedesktop.org/software/systemd/man/latest/systemd-analyze.html) — Full reference for `blame`, `critical-chain`, `plot`, `verify`, `security`, and `calendar` subcommands used to profile and lint systemd configuration.
- [systemd.socket(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.socket.html) — Authoritative reference for socket activation: `ListenStream=`, `Accept=`, `SocketUser=`, and passing file descriptors via `sd_listen_fds()`.
- [systemd.slice(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.slice.html) — Documents slice units used to group services into cgroup hierarchies for resource accounting and limits.
- [Arch Wiki — systemd/User](https://wiki.archlinux.org/title/Systemd/User) — Complete guide to user-level systemd instances: unit file locations, `loginctl enable-linger`, and `systemctl --user` patterns.
- [systemd — The New Control Group Interfaces](https://systemd.io/CGROUP_DELEGATION/) — Explains how systemd manages cgroup v2 delegation, critical context for the `MemoryMax=`, `CPUQuota=`, and `TasksMax=` resource limits.
