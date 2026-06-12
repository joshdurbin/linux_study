# Exercise: Security Hardening

## Task 1 — File capabilities audit

Create `~/seclab/`. Scan for binaries with capabilities set:

```bash
getcap -r /usr/bin/ 2>/dev/null > ~/seclab/capabilities.txt
getcap -r /usr/sbin/ 2>/dev/null >> ~/seclab/capabilities.txt
```

If the files are empty (no capabilities set), write `none found` to the file. Then check for setuid binaries:

```bash
find /usr/bin /usr/sbin /bin /sbin -perm /u+s -type f 2>/dev/null > ~/seclab/setuid_bins.txt
```

## Task 2 — sudo inspection

1. Run `sudo -l` and save to `~/seclab/sudo_privs.txt`
2. View `/etc/sudoers` and save to `~/seclab/sudoers.txt` (you may need `sudo cat /etc/sudoers`)
3. List `/etc/sudoers.d/` and save to `~/seclab/sudoers_d.txt`

## Task 3 — PAM config

1. Save `/etc/pam.d/sudo` to `~/seclab/pam_sudo.txt`
2. Save `/etc/pam.d/login` to `~/seclab/pam_login.txt`
3. List all files in `/etc/pam.d/` and save to `~/seclab/pam_configs.txt`

## Task 4 — ufw status and listening services

1. Run `sudo ufw status` and save to `~/seclab/ufw_status.txt`
2. Run `ss -tulnp` and save to `~/seclab/listening_services.txt`
3. Find any world-writable files in `/tmp` using `find /tmp -perm -o+w -type f 2>/dev/null` and save to `~/seclab/world_writable.txt` (may be empty — that's fine)
