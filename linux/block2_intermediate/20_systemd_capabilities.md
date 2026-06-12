# systemd Service Hardening and Capabilities

A poorly written unit file runs a service as root with full system access. Modern systemd provides a rich set of security directives that limit what a service can do — without any changes to the application itself. These are the Linux security primitives (capabilities, namespaces, seccomp) exposed as simple unit file options.

## Linux Capabilities — What They Are

Traditional Unix: root can do everything, non-root can't. Capabilities split root's privilege into discrete units so a process can have exactly the access it needs.

```bash
# List all capabilities
man capabilities | grep "CAP_"

# Check capabilities of a running process
cat /proc/$$/status | grep -i cap
# CapInh: inherited
# CapPrm: permitted
# CapEff: effective (what's actually usable right now)
# CapBnd: bounding set (ceiling — cannot exceed this)
# CapAmb: ambient (retained across exec)

# Human-readable view
capsh --decode=$(cat /proc/$$/status | awk '/^CapEff/{print $2}')
```

### Common Capabilities

| Capability | What It Allows |
|-----------|---------------|
| `CAP_NET_BIND_SERVICE` | Bind to ports < 1024 |
| `CAP_NET_RAW` | Use raw sockets (ping, tcpdump) |
| `CAP_NET_ADMIN` | Network config (ip, tc, iptables) |
| `CAP_SYS_ADMIN` | Broad system admin (mount, ptrace, etc.) |
| `CAP_SYS_PTRACE` | Trace other processes |
| `CAP_DAC_OVERRIDE` | Bypass file permission checks |
| `CAP_SETUID` / `CAP_SETGID` | Change UID/GID |
| `CAP_KILL` | Send signals to any process |
| `CAP_SYS_TIME` | Set system clock |
| `CAP_CHOWN` | Change file ownership |

`CAP_SYS_ADMIN` is the "god mode" capability — treat it like root.

## Key systemd Hardening Directives

### Identity and Privilege

```ini
[Service]
User=myapp              # run as this user (not root)
Group=myapp             # run as this group
DynamicUser=yes         # create a transient user at startup (no /etc/passwd entry)
                        # implies PrivateTmp=yes and removes home/shell access
```

### Capability Control

```ini
[Service]
# Remove all capabilities except what's listed
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_NET_RAW

# Grant specific capabilities even when running as non-root
AmbientCapabilities=CAP_NET_BIND_SERVICE

# Prevent the process from gaining new privileges (setuid, capabilities)
NoNewPrivileges=yes
```

`NoNewPrivileges=yes` is the single most impactful directive. It prevents setuid binaries, `sudo`, and `su` from working within the service — a compromised process cannot escalate.

### Filesystem Isolation

```ini
[Service]
PrivateTmp=yes          # isolated /tmp and /var/tmp (tmpfs, invisible to others)
PrivateDevices=yes      # no /dev except null, zero, random, urandom, tty
ProtectSystem=strict    # /usr, /boot, /etc read-only (use ReadWritePaths= for exceptions)
ProtectHome=yes         # no access to /home, /root, /run/user
ReadOnlyPaths=/etc      # explicitly read-only
ReadWritePaths=/var/lib/myapp   # allow writes here only
InaccessiblePaths=/proc/sysrq-trigger /sys/firmware
```

`ProtectSystem=strict` + `ReadWritePaths=` is the best pattern for production services: deny everything, allow the minimum.

### Network Isolation

```ini
[Service]
PrivateNetwork=yes      # completely isolated network namespace (only loopback)
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX  # limit socket families
IPAddressDeny=any               # block all outbound IP
IPAddressAllow=192.168.1.0/24  # except this range
```

### Syscall Filtering (systemd-integrated seccomp)

```ini
[Service]
SystemCallFilter=@system-service    # allow a curated set for typical daemons
SystemCallFilter=~@privileged @resources   # deny dangerous groups
SystemCallErrorNumber=EPERM         # return EPERM instead of killing on denied syscall
```

Predefined groups: `@system-service`, `@network-io`, `@basic-io`, `@privileged`, `@resources`, `@clock`, `@module`, `@raw-io`, `@reboot`, `@swap`, `@obsolete`.

### Namespace Isolation

```ini
[Service]
ProtectKernelTunables=yes   # /proc/sys and /sys read-only
ProtectKernelModules=yes    # cannot load/unload kernel modules
ProtectKernelLogs=yes       # no access to kernel log ring buffer
ProtectControlGroups=yes    # /sys/fs/cgroup read-only
RestrictNamespaces=yes      # cannot create new namespaces (prevents container escape)
LockPersonality=yes         # cannot change execution domain
MemoryDenyWriteExecute=yes  # cannot create writable+executable memory mappings
RestrictRealtime=yes        # cannot set real-time scheduling
RestrictSUIDSGID=yes        # cannot create setuid/setgid files
```

### Resource Limits in Unit Files

```ini
[Service]
LimitNOFILE=65536       # max open file descriptors (overrides ulimit)
LimitNPROC=512          # max child processes
LimitMEMLOCK=infinity   # for apps that lock memory (Redis, databases)
TasksMax=512            # max number of threads/tasks
MemoryMax=2G            # cgroup memory limit (OOM kills at this)
CPUQuota=200%           # cap CPU to 2 cores worth
```

## Checking a Service's Security Score

```bash
# systemd-analyze security shows the hardening score for a unit
systemd-analyze security nginx.service

# Output:
# NAME                                  DESCRIPTION                  EXPOSURE
# PrivateNetwork=                       Service has access to network  0.5
# User=/DynamicUser=                    Service runs as root          0.4 WARN
# NoNewPrivileges=                      Service may acquire new privs  0.2
# ...
# → Overall exposure level for nginx.service: 9.6 DANGEROUS

# Compare a hardened service
systemd-analyze security sshd.service
```

## A Hardened Service Template

```ini
[Unit]
Description=My Hardened App
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/myapp
Restart=on-failure

# Identity
User=myapp
Group=myapp
DynamicUser=no          # use pre-created user for consistent UIDs

# No privilege escalation
NoNewPrivileges=yes

# Minimal capabilities (app needs port 8080 only — no special caps needed)
CapabilityBoundingSet=

# Filesystem isolation
PrivateTmp=yes
PrivateDevices=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/lib/myapp /var/log/myapp

# Syscall filter
SystemCallFilter=@system-service
SystemCallErrorNumber=EPERM

# Namespace protection
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
RestrictNamespaces=yes
LockPersonality=yes
MemoryDenyWriteExecute=yes

# Network
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX

# Resource limits
LimitNOFILE=65536
MemoryMax=512M
TasksMax=128

[Install]
WantedBy=multi-user.target
```

## Iterating on Restrictions

```bash
# Start broad, tighten incrementally:

# 1. Run the service and check if it starts
systemctl start myapp
journalctl -u myapp -n 20

# 2. Check for EPERM errors (syscall filter denials)
journalctl -u myapp | grep -i "operation not permitted\|EPERM"

# 3. Find what the service actually needs
strace -p $(pgrep myapp) -e trace=all -c 2>/dev/null &  # then restart
# Or check the exposure score and fix the worst items first:
systemd-analyze security myapp.service
```

## Further Reading

- [man7.org — capabilities(7)](https://man7.org/linux/man-pages/man7/capabilities.7.html) — The authoritative reference for every `CAP_*` constant, the five capability sets (effective, permitted, inheritable, bounding, ambient), and how they change across `fork`/`execve`.
- [systemd.exec(5) — Sandboxing](https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html) — Full reference for every sandboxing directive: `CapabilityBoundingSet=`, `NoNewPrivileges=`, `ProtectSystem=`, `SystemCallFilter=`, and namespace isolation options.
- [Arch Wiki — Capabilities](https://wiki.archlinux.org/title/Capabilities) — Practical guide to viewing, setting, and removing file capabilities with `getcap`/`setcap`, and ambient capabilities for non-root services.
- [Julia Evans — A few Linux security features](https://jvns.ca/blog/2022/09/09/a-couple-of-linux-security-features/) — Accessible introduction to seccomp and capabilities with concrete examples of how they limit what a compromised process can do.
- [man7.org — seccomp(2)](https://man7.org/linux/man-pages/man2/seccomp.2.html) — Documents the seccomp syscall filter mechanism that `SystemCallFilter=` in systemd units is built on.
