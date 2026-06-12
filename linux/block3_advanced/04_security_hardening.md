# Security Hardening

Linux security is layered. This lesson covers practical hardening: file capabilities, Linux namespaces, sudo configuration, PAM, and basic network firewall rules.

## File Capabilities

Traditional Unix security uses setuid bits — a binary runs as its owner (often root). Capabilities break root's privileges into granular units so programs can have just what they need.

```bash
# View capabilities
getcap /usr/bin/ping              # CAP_NET_RAW typically
getcap -r /usr/bin/ 2>/dev/null   # recursive scan
getpcaps $$                       # capabilities of current process

# Set capabilities
sudo setcap cap_net_bind_service=+ep /usr/bin/node  # bind port < 1024
sudo setcap -r /usr/bin/node                        # remove all caps
```

Common capabilities:
| Capability | Allows |
|-----------|--------|
| `CAP_NET_BIND_SERVICE` | Bind to ports below 1024 |
| `CAP_NET_RAW` | Raw sockets (ping, tcpdump) |
| `CAP_SYS_ADMIN` | Many admin operations (broad!) |
| `CAP_SETUID` | Change UID |
| `CAP_KILL` | Kill processes of other users |

## Linux Namespaces

Namespaces isolate process views of system resources — the foundation of containers.

```bash
# List namespaces of a process
ls -la /proc/$$/ns/

# Create a new mount namespace (process can mount without affecting host)
sudo unshare --mount bash

# New network namespace
sudo unshare --net bash            # has only lo interface
ip addr                            # shows only loopback

# Full isolation like a container
sudo unshare --pid --fork --mount-proc bash

# View namespace identifiers
lsns                               # list all namespaces on system
lsns -p $$                         # namespaces of current process
```

Namespace types: `mnt`, `uts`, `ipc`, `net`, `pid`, `user`, `cgroup`

## sudo and sudoers

`sudo` lets specific users run commands as root (or other users) with logging.

```bash
sudo -l                    # list your sudo privileges
sudo -i                    # interactive root shell
sudo -u alice command      # run as alice
sudo -e /etc/hosts         # edit as root using $SUDO_EDITOR

# Edit sudoers safely (validates syntax before saving)
sudo visudo
```

`/etc/sudoers` syntax:
```
# Format: who  where=(as_whom)  command
alice   ALL=(ALL:ALL) ALL            # alice can run anything as root
bob     ALL=(ALL) NOPASSWD: /bin/ls  # bob can ls as root without password
%devs   ALL=(ALL) /usr/bin/apt       # group devs can run apt
```

Drop-in files in `/etc/sudoers.d/` are safer — package your rules separately.

```bash
# Create a sudoers drop-in
sudo visudo -f /etc/sudoers.d/alice
```

## PAM — Pluggable Authentication Modules

PAM provides a flexible framework for authentication. Config files are in `/etc/pam.d/`.

```bash
ls /etc/pam.d/                # PAM config for each service
cat /etc/pam.d/sudo           # how sudo authenticates
cat /etc/pam.d/sshd           # how sshd authenticates
cat /etc/security/limits.conf # resource limits via PAM limits module
```

PAM stack control values:
- `required` — must succeed, but continue evaluating
- `requisite` — fail immediately if not satisfied
- `sufficient` — if succeeds and no previous required failed, skip rest
- `optional` — result only matters if it's the only module

Common PAM modules: `pam_unix.so` (password), `pam_limits.so` (ulimits), `pam_google_authenticator.so` (2FA).

## ufw — Uncomplicated Firewall

```bash
sudo ufw status              # show rules and state
sudo ufw status verbose      # detailed
sudo ufw enable              # activate firewall
sudo ufw disable             # deactivate

sudo ufw allow 22/tcp        # allow SSH
sudo ufw allow http          # allow port 80 (by service name)
sudo ufw allow 8080          # allow TCP port 8080
sudo ufw deny 23             # block telnet
sudo ufw allow from 192.168.1.0/24 to any port 22  # restrict SSH by source
sudo ufw delete allow 8080   # remove a rule

sudo ufw default deny incoming   # block all incoming by default
sudo ufw default allow outgoing  # allow all outgoing
```

## fail2ban — Brute Force Protection

fail2ban watches log files and bans IPs that show repeated failed auth.

```bash
sudo systemctl status fail2ban
sudo fail2ban-client status                  # list active jails
sudo fail2ban-client status sshd             # sshd jail details
sudo fail2ban-client unban 192.168.1.100     # unban an IP
cat /etc/fail2ban/jail.conf                  # global config
cat /etc/fail2ban/jail.local                 # local overrides (create this)
```

Example `/etc/fail2ban/jail.local`:
```ini
[sshd]
enabled = true
maxretry = 5
bantime = 3600
findtime = 600
```

## Practical Security Checklist

```bash
# Check for world-writable files
find / -perm -o+w -not -type l 2>/dev/null | grep -v proc

# Find setuid/setgid binaries
find / -perm /u+s -type f 2>/dev/null
find / -perm /g+s -type f 2>/dev/null

# Check listening services
ss -tulnp

# Review sudo rules
sudo cat /etc/sudoers
ls /etc/sudoers.d/

# Check for empty passwords
sudo awk -F: '($2 == "") {print $1}' /etc/shadow
```

## Further Reading

- [capabilities(7) — man7.org](https://man7.org/linux/man-pages/man7/capabilities.7.html) — definitive reference for every Linux capability constant (`CAP_NET_BIND_SERVICE`, `CAP_SYS_ADMIN`, etc.), the bounding set, ambient capabilities, and the rules for capability inheritance across `exec`.
- [setcap(8) — man7.org](https://man7.org/linux/man-pages/man8/setcap.8.html) — documents the `setcap`/`getcap` tools and the `capability = flags` syntax for assigning effective, permitted, and inheritable capability sets to files.
- [Linux Hardening Guide — madaidan](https://madaidans-insecurities.github.io/guides/linux-hardening.html) — comprehensive, opinionated hardening guide covering kernel hardening, sysctl knobs, MAC, capabilities, and common misconfigurations with specific remediation steps.
- [Arch Wiki — Security](https://wiki.archlinux.org/title/Security) — practical hardening checklist covering file permissions, sudo configuration, PAM, kernel parameters, and firewall setup with concrete commands applicable to any Linux distribution.
- [PAM documentation — The Linux-PAM System Administrators' Guide](https://www.linux-pam.org/Linux-PAM-html/Linux-PAM_SAG.html) — official PAM documentation covering the module stack, control flags (`required`, `requisite`, `sufficient`), and how to configure `pam_limits.so` and `pam_unix.so`.
