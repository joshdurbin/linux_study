# SELinux and AppArmor — Mandatory Access Control

Linux's standard permissions (DAC — Discretionary Access Control) let the file owner decide who can access their files. **MAC (Mandatory Access Control)** adds a system-wide policy that overrides owner decisions — even root cannot bypass it.

Two implementations dominate:
- **SELinux** — label-based, fine-grained, used on RHEL/CentOS/Fedora
- **AppArmor** — path-based, simpler to write, used on Ubuntu/Debian

Ubuntu uses AppArmor by default. This lesson covers both, with AppArmor as the hands-on focus.

## AppArmor

AppArmor confines programs using profiles. Each profile specifies what files, capabilities, and network access a program may use. Running without a profile = unconfined (no restriction beyond DAC).

### Checking AppArmor Status

```bash
# Is AppArmor enabled?
sudo aa-status

# Output shows:
# - AppArmor module is loaded
# - Number of profiles in enforce/complain mode
# - Which profiles apply to which PIDs

# Simpler status check
cat /sys/module/apparmor/parameters/enabled   # Y or N

# See the current enforcement mode
sudo apparmor_status | head -20
```

### Profile Modes

| Mode | Behavior |
|------|---------|
| `enforce` | Policy violations are **blocked** and logged |
| `complain` | Policy violations are **allowed** but logged (used for profiling) |
| `disabled` | Profile is loaded but not applied |
| unconfined | No profile — process has full DAC access |

```bash
# Put a profile in complain mode
sudo aa-complain /etc/apparmor.d/usr.sbin.nginx

# Put a profile in enforce mode
sudo aa-enforce /etc/apparmor.d/usr.sbin.nginx

# Disable a profile
sudo aa-disable /etc/apparmor.d/usr.sbin.nginx

# Reload a profile after editing
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.nginx
```

### Reading a Profile

```bash
cat /etc/apparmor.d/usr.bin.man   # example: man page reader profile
```

```
#include <tunables/global>

/usr/bin/man {
  #include <abstractions/base>
  #include <abstractions/consoles>

  /usr/bin/man          mr,    # the binary itself: map+read
  /usr/share/man/**     r,     # read man pages
  /usr/lib/man-db/**    mr,    # man-db helpers
  /tmp/**               rw,    # temp files for decompression
  /dev/tty              rw,    # terminal access

  capability setuid,           # needed to drop privileges
}
```

**Permission flags:**
| Flag | Meaning |
|------|---------|
| `r` | read |
| `w` | write |
| `a` | append |
| `x` | execute |
| `m` | mmap with PROT_EXEC |
| `k` | lock |
| `l` | link |

### Writing a Simple Profile

```bash
# Start in complain mode to observe what the program actually does
sudo aa-genprof /usr/local/bin/myscript   # interactive profile generator

# Or write one manually:
cat > /tmp/myapp_profile << 'EOF'
#include <tunables/global>

/usr/local/bin/myapp {
  #include <abstractions/base>

  /usr/local/bin/myapp mr,
  /var/log/myapp.log   rw,
  /etc/myapp.conf      r,

  # Deny network access
  deny network,
}
EOF

sudo cp /tmp/myapp_profile /etc/apparmor.d/usr.local.bin.myapp
sudo apparmor_parser -r /etc/apparmor.d/usr.local.bin.myapp
```

### AppArmor Logs

AppArmor denials appear in `/var/log/syslog` or the kernel audit log:

```bash
# Find AppArmor denials
sudo grep "apparmor" /var/log/syslog | grep "DENIED" | tail -20

# Or via dmesg
dmesg | grep -i apparmor | tail -20

# Or via journalctl (block2/06)
journalctl -k | grep -i "apparmor.*DENIED" | tail -20
```

A denial looks like:
```
kernel: audit: type=1400 audit(1710000000.000:42):
  apparmor="DENIED" operation="open" profile="/usr/bin/python3"
  name="/etc/shadow" pid=1234 comm="python3" requested_mask="r" denied_mask="r"
  fsuid=1000 ouid=0
```

Fields: `profile` = which profile triggered, `name` = the resource denied, `requested_mask` = what was asked for, `denied_mask` = what was blocked.

## SELinux Concepts (RHEL/Fedora)

SELinux is not active on Ubuntu, but understanding it is essential for RHEL-based systems.

### Labels — The Core of SELinux

Every file, process, and socket has a **security context** (label):
```
user:role:type:level
system_u:object_r:httpd_exec_t:s0   ← a file label
unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023  ← process label
```

The **type** component is what most policies use. A web server process with type `httpd_t` can only access files with types that the policy explicitly allows (e.g., `httpd_sys_content_t`).

### Key SELinux Commands (RHEL)

```bash
# View current mode
getenforce              # Enforcing / Permissive / Disabled

# Temporarily set to permissive (survives until next boot)
sudo setenforce 0       # permissive
sudo setenforce 1       # enforcing

# Permanent mode change: /etc/selinux/config → SELINUX=permissive

# View label of files
ls -Z /var/www/html/

# View label of processes
ps -Z | head -10

# View label of your shell
id -Z

# Check for recent AVC (access vector cache) denials
sudo ausearch -m AVC -ts recent
sudo sealert -a /var/log/audit/audit.log   # human-readable analysis

# Fix a mislabeled file
sudo restorecon -v /var/www/html/index.html

# Set a specific label
sudo chcon -t httpd_sys_content_t /var/www/html/myfile.html

# Boolean toggles (enable/disable policy modules without rewriting policy)
sudo getsebool -a | grep httpd
sudo setsebool -P httpd_can_network_connect on   # -P = persistent
```

### SELinux vs AppArmor: Key Differences

| | SELinux | AppArmor |
|--|---------|---------|
| Model | Label-based | Path-based |
| Learning curve | High | Low |
| Scope | Everything (files, sockets, IPC) | Files + capabilities + network |
| Default distros | RHEL, Fedora, CentOS | Ubuntu, Debian, SUSE |
| Policy language | Complex, compiled | Simple text files |
| Debugging | `ausearch`, `sealert` | Syslog grep |

## Further Reading

- [AppArmor wiki — gitlab.com](https://gitlab.com/apparmor/apparmor/-/wikis/Documentation) — the official AppArmor documentation: profile language reference, abstraction files, `aa-genprof` / `aa-logprof` workflow, and mount/network/dbus rules beyond file access.
- [apparmor(7) — man7.org](https://man7.org/linux/man-pages/man7/apparmor.7.html) — man page overview of the AppArmor module: enforcement vs complain mode, how profiles are loaded, the `/proc/PID/attr/current` interface, and transition rules.
- [Ubuntu AppArmor guide](https://ubuntu.com/server/docs/security-apparmor) — Ubuntu's practical AppArmor guide covering `aa-status`, `aa-enforce`, `aa-complain`, reading denial logs, and the abstractions shipped with Ubuntu for common use cases.
- [SELinux Project](https://selinuxproject.org/page/Main_Page) — the upstream SELinux project site with policy writing tutorials, `audit2allow` usage, boolean reference, and the type enforcement (TE) language specification.
- [capabilities(7) — man7.org](https://man7.org/linux/man-pages/man7/capabilities.7.html) — documents every capability constant and explains how capabilities interact with AppArmor (`capability` rules) and SELinux (`capability` class rules) at the LSM hook layer.
