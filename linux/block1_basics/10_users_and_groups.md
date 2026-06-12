# Users and Groups

Linux is a multi-user system. Every file, process, and resource has an owner (user) and group. Understanding user management is essential for administration and security.

## Identifying Yourself

```bash
whoami              # print current username
id                  # UID, GID, and all group memberships
id alice            # id for another user
id -u               # just the UID number
id -g               # just the primary GID
id -G               # all GID numbers
id -Gn              # all group names
```

## /etc/passwd — User Database

Each line: `username:x:UID:GID:comment:home:shell`

```bash
cat /etc/passwd                    # all users
grep alice /etc/passwd             # find a specific user
getent passwd alice                # look up via Name Service Switch
cut -d: -f1 /etc/passwd | sort    # list all usernames
```

Key system accounts: `root` (UID 0), `daemon`, `www-data`, `nobody`.
The `x` in the password field means the hash is in `/etc/shadow` (root-readable only).

## groups and id

```bash
groups              # groups current user belongs to
groups alice        # groups for another user
```

## useradd and adduser

```bash
sudo useradd alice                   # low-level: create user (no home, no shell)
sudo useradd -m alice                # create with home directory
sudo useradd -m -s /bin/bash alice   # with bash shell
sudo useradd -m -G sudo,docker alice # with supplementary groups

# adduser is the friendlier Debian/Ubuntu frontend
sudo adduser alice                   # interactive: prompts for password etc.
```

## usermod — Modify User

```bash
sudo usermod -aG docker alice     # add alice to docker group (-a = append!)
sudo usermod -aG sudo alice       # add to sudo group
sudo usermod -s /bin/zsh alice    # change shell
sudo usermod -d /new/home alice   # change home directory
sudo usermod -L alice             # lock account (disable password login)
sudo usermod -U alice             # unlock account
```

`-a` (append) is critical with `-G` — without it, the user is removed from all other groups.

## passwd — Set Password

```bash
passwd              # change your own password
sudo passwd alice   # set alice's password (as root)
sudo passwd -l alice  # lock alice's account
sudo passwd -u alice  # unlock
sudo passwd -e alice  # expire: force password change on next login
```

## su — Switch User

```bash
su alice            # switch to alice (requires alice's password)
su - alice          # switch + load alice's environment (the dash matters!)
su -                # switch to root
sudo su -           # switch to root using sudo
```

`su -` (with dash) sources the target user's login profile, setting their PATH, HOME, etc.

## groupadd and Group Management

```bash
sudo groupadd developers          # create a group
sudo groupmod -n devs developers  # rename group
sudo gpasswd -a alice devs        # add alice to devs
sudo gpasswd -d alice devs        # remove alice from devs
sudo delgroup devs                # delete group
cat /etc/group                    # group database: name:x:GID:members
```

## userdel

```bash
sudo userdel alice           # delete user (keeps home directory)
sudo userdel -r alice        # delete user AND home directory
```

## Practical Checks

```bash
# Is this user in the sudo group?
groups alice | grep -q sudo && echo "has sudo" || echo "no sudo"

# Show UID/GID for all users
awk -F: '{print $1, $3, $4}' /etc/passwd

# Who is logged in right now?
who
w
last | head -20    # recent logins
```

## Key Files

| File | Contents |
|------|----------|
| `/etc/passwd` | User accounts (world-readable) |
| `/etc/shadow` | Password hashes (root only) |
| `/etc/group` | Group memberships |
| `/etc/sudoers` | sudo rules (edit with visudo) |

## Further Reading

- [man7.org — passwd(5)](https://man7.org/linux/man-pages/man5/passwd.5.html) — Documents every field in `/etc/passwd` including UID ranges, home directory conventions, and the shell field.
- [man7.org — shadow(5)](https://man7.org/linux/man-pages/man5/shadow.5.html) — Explains the `/etc/shadow` format: password hash algorithms (SHA-512 `$6$`), aging fields, and account expiry.
- [Linux PAM Documentation](https://www.kernel.org/pub/linux/libs/pam/) — The Pluggable Authentication Modules system that controls how `login`, `su`, and `sudo` verify identity and enforce policy.
- [Arch Wiki — Users and groups](https://wiki.archlinux.org/title/Users_and_groups) — Practical guide to `useradd`, `usermod`, group management, and UID/GID conventions on Linux.
- [man7.org — getent(1)](https://man7.org/linux/man-pages/man1/getent.1.html) — Explains how `getent passwd` queries Name Service Switch (NSS) — important when users come from LDAP rather than `/etc/passwd`.
