# Linux Audit Framework (auditd)

The Linux audit framework records security-relevant events at the kernel level — file access, syscalls, user logins, privilege escalation. It's the primary tool for compliance (PCI-DSS, SOC2, HIPAA) and forensic investigation.

## Architecture

```
kernel audit subsystem
    ↓
/dev/audit (netlink socket)
    ↓
auditd daemon → /var/log/audit/audit.log
    ↓
ausearch / aureport (analysis tools)
```

The kernel generates audit records; `auditd` collects and persists them. Records are written even if `auditd` isn't running — they queue in a kernel buffer (configurable size).

## auditctl — Managing Audit Rules

Rules define what events to record. Three types:
- **Watch rules** (`-w`) — monitor file/directory access
- **Syscall rules** (`-a`) — record when a specific syscall fires
- **Control rules** (`-e`, `-b`) — configure the audit system itself

```bash
# View current rules
sudo auditctl -l

# View audit system status
sudo auditctl -s

# Watch a file for all access types (r=read, w=write, x=execute, a=attribute change)
sudo auditctl -w /etc/passwd -p rwxa -k passwd_watch

# Watch a directory recursively
sudo auditctl -w /etc/sudoers.d/ -p wa -k sudoers_change

# Watch for execution of a specific binary
sudo auditctl -w /usr/bin/sudo -p x -k sudo_use

# Audit a syscall (audit any process calling setuid)
sudo auditctl -a always,exit -F arch=b64 -S setuid -k setuid_call

# Audit failed file opens by a specific user (UID 1000)
sudo auditctl -a always,exit -F arch=b64 -S open -F uid=1000 -F exit=-EACCES -k access_denied

# Delete a specific rule
sudo auditctl -W /etc/passwd -p rwxa -k passwd_watch

# Delete all rules
sudo auditctl -D
```

The `-k` flag sets a **key** — a string tag that makes it easy to search for related events later.

## /var/log/audit/audit.log — The Raw Log

```bash
# Tail the audit log in real time
sudo tail -f /var/log/audit/audit.log

# A typical audit record:
# type=SYSCALL msg=audit(1710000000.123:456): arch=c000003e syscall=2 success=yes
#   exit=3 a0=7ffca0001234 a1=0 a2=1b6 a3=0 items=1 ppid=1234 pid=5678
#   auid=1000 uid=0 gid=0 euid=0 ... comm="cat" exe="/usr/bin/cat" key="passwd_watch"
#
# type=PATH msg=audit(1710000000.123:456): item=0 name="/etc/passwd"
#   inode=131073 dev=08:01 mode=0100644 ... nametype=NORMAL

# Fields:
# type     — record type (SYSCALL, PATH, USER_AUTH, USER_CMD, etc.)
# auid     — audit user ID (the original login UID, survives su/sudo)
# uid/euid — real and effective UID at time of event
# key      — the -k tag you set in the rule
# comm     — command name; exe — full path of binary
```

## ausearch — Search Audit Logs

```bash
# Search by key tag
sudo ausearch -k passwd_watch

# Search by time range
sudo ausearch -ts today
sudo ausearch -ts "2024-03-15 09:00:00" -te "2024-03-15 17:00:00"
sudo ausearch -ts recent   # last 10 minutes

# Search by user
sudo ausearch -ua 1000     # by audit UID (original login user)
sudo ausearch -ui 1000     # by UID

# Search by executable
sudo ausearch -x /usr/bin/sudo

# Search by syscall name
sudo ausearch -sc open

# Search for failures only
sudo ausearch -sv no       # success=no events

# Combine: failed opens by root
sudo ausearch -sv no -sc open -ui 0

# Interpret records in readable format
sudo ausearch -k passwd_watch -i    # -i interprets UID/GID to names, syscall numbers to names
```

## aureport — Summary Reports

```bash
# Summary of all events
sudo aureport

# Authentication events report
sudo aureport -au

# Executable report (most-used binaries)
sudo aureport -x

# Failed events
sudo aureport --failed

# Summary by event type
sudo aureport -e

# Events in a time range
sudo aureport -ts today --summary

# Anomalies (unusual patterns)
sudo aureport -a

# Login report
sudo aureport -l
```

## Persistent Audit Rules

Runtime rules (`auditctl -a/w`) are lost on reboot. Persist them in `/etc/audit/rules.d/`:

```bash
# Create a ruleset file
sudo tee /etc/audit/rules.d/sre-baseline.rules << 'EOF'
# Delete existing rules
-D

# Buffer size
-b 8192

# Failure mode: 1=printk, 2=panic on overrun
-f 1

# Watch key system files
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers

# Watch SSH config and keys
-w /etc/ssh/sshd_config -p wa -k sshd_config
-w /root/.ssh -p wa -k ssh_keys

# Privilege escalation
-w /usr/bin/sudo -p x -k sudo_use
-a always,exit -F arch=b64 -S setuid -S setgid -k priv_esc

# Module loading
-w /sbin/insmod -p x -k module_insert
-w /sbin/rmmod -p x -k module_remove
-a always,exit -F arch=b64 -S init_module -k module_load

# Make rules immutable (requires reboot to change — use with caution)
# -e 2
EOF

# Load the new rules
sudo augenrules --load
```

## Common Investigation Workflows

```bash
# Who ran sudo in the last hour?
sudo ausearch -ts recent -k sudo_use -i | grep -E "^uid|exe|comm"

# What files did PID 1234 open?
sudo ausearch -p 1234 -sc open -i

# Did anyone modify /etc/passwd today?
sudo ausearch -k identity -ts today -i | grep passwd

# Show all failed authentication attempts
sudo aureport -au --failed -ts today

# Full audit trail for a username (login through all actions)
AUID=$(id -u username 2>/dev/null || echo 1000)
sudo ausearch -ua $AUID -ts today -i
```

## Further Reading

- [Red Hat — Auditing the System](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/security_hardening/auditing-the-system_security-hardening) — comprehensive production guide to the Linux audit framework: rule syntax, compliance rule sets, and integrating audit logs with SIEM systems.
- [auditctl(8) — man7.org](https://man7.org/linux/man-pages/man8/auditctl.8.html) — definitive reference for all `-w`, `-a`, `-e`, and `-b` rule syntax, filter fields (`-F arch=`, `-F uid=`, `-F exit=`), and the key (`-k`) tagging mechanism.
- [ausearch(8) — man7.org](https://man7.org/linux/man-pages/man8/ausearch.8.html) — complete `ausearch` reference covering time range filters (`-ts`, `-te`), UID/AUID selectors, syscall name filters, and the `-i` flag for human-readable output.
- [Linux Audit System — kernel.org](https://www.kernel.org/doc/html/latest/security/audit.html) — kernel-level documentation of the audit netlink socket protocol, buffer sizing (`-b`), failure modes (`-f 1` vs `-f 2`), and how audit records are assembled by the kernel.
- [aureport(8) — man7.org](https://man7.org/linux/man-pages/man8/aureport.8.html) — documents all `aureport` modes (`-au`, `-x`, `-l`, `-e`, `--failed`, `--summary`) for generating compliance-ready summaries from the audit log.
