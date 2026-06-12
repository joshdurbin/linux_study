# Permissions

Linux uses a discretionary access control model: every file has an owner, a group, and a permission set. Understanding permissions is essential for security and for running services correctly.

## Reading Permission Bits

```
-rwxr-xr--  1  alice  devs  4096  Jan 1  file.sh
^            ^  ^^^^^  ^^^^
|            |  owner  group
|            link count
file type: - = regular, d = dir, l = symlink, b = block dev
```

The 9 permission characters:
```
rwx  r-x  r--
^^^  ^^^  ^^^
|    |    world (others)
|    group
owner (user)
```

Each `rwx` position: `r` = read, `w` = write, `x` = execute (or traverse for directories).

## chmod — Change Permissions

### Symbolic mode

```bash
chmod u+x script.sh          # add execute for owner
chmod g-w file.txt           # remove write for group
chmod o=r file.txt           # set others to read-only
chmod a+r file.txt           # add read for all (a = ugo)
chmod u+x,g-w file.txt       # multiple changes at once
chmod -R g+r directory/      # recursive
```

### Octal mode

Each digit = 3 bits (r=4, w=2, x=1):
```
7 = rwx  (4+2+1)
6 = rw-  (4+2)
5 = r-x  (4+1)
4 = r--  (4)
0 = ---  (0)
```

```bash
chmod 755 script.sh     # rwxr-xr-x (owner full, group+others rx)
chmod 644 config.txt    # rw-r--r-- (owner rw, others r)
chmod 600 .ssh/id_rsa   # rw------- (private key: owner only)
chmod 700 .ssh/         # rwx------ (ssh dir: owner only)
chmod 777 shared/       # rwxrwxrwx (everyone full — avoid this)
chmod 000 locked.txt    # no permissions for anyone
```

## chown — Change Owner and Group

```bash
chown alice file.txt           # change owner to alice
chown alice:devs file.txt      # change owner and group
chown :devs file.txt           # change group only
chown -R alice:alice /home/alice/  # recursive
```

You must be root (or use sudo) to change file ownership.

## umask — Default Permission Mask

When a file is created, the permissions are `mode AND NOT umask`:

```bash
umask            # show current mask (e.g., 0022)
umask 027        # set mask: new files get at most 750
umask -S         # show in symbolic form
```

Common umask values:
- `0022` — files: 644, dirs: 755 (typical default)
- `0027` — files: 640, dirs: 750 (stricter, group can read)
- `0077` — files: 600, dirs: 700 (private)

## Special Bits

```bash
# Setuid (s in owner execute position): run as file's owner
chmod u+s /usr/bin/passwd   # or chmod 4755

# Setgid (s in group execute position): 
# On executable: run as file's group
# On directory: new files inherit directory's group
chmod g+s shared_dir/       # or chmod 2755

# Sticky bit (t in others execute position):
# On directory: only owner can delete their own files
chmod +t /tmp               # or chmod 1777
ls -ld /tmp                 # shows drwxrwxrwt
```

## sudo — Run as Another User

```bash
sudo command              # run as root
sudo -u alice command     # run as alice
sudo -i                   # interactive root shell
sudo -l                   # list your sudo privileges
sudo !!                   # re-run last command with sudo
```

`sudo` is configured in `/etc/sudoers` (edit with `visudo` — never directly).

## Practical Security Defaults

| File type | Typical permission |
|-----------|-------------------|
| Private key | 600 |
| Config file | 644 |
| Shell script | 755 |
| Sensitive config | 640 |
| Directory | 755 |
| Shared writable dir | 1777 (sticky) |

## Further Reading

- [man7.org — capabilities(7)](https://man7.org/linux/man-pages/man7/capabilities.7.html) — Complete list of every `CAP_*` constant, the five capability sets, and why setuid binaries like `passwd` work without full root.
- [man7.org — chmod(2)](https://man7.org/linux/man-pages/man2/chmod.2.html) — The syscall reference documenting how permission bits (setuid, setgid, sticky) are stored in the inode `mode_t` field.
- [Arch Wiki — File permissions and attributes](https://wiki.archlinux.org/title/File_permissions_and_attributes) — Clear explanation of rwx bits, octal notation, special bits, and ACLs with practical examples.
- [The Linux Command Line — Permissions](https://linuxcommand.org/tlcl.php) — Chapter 9 covers `chmod`, `chown`, `umask`, and the setuid/setgid/sticky bits with real-world context.
- [man7.org — umask(2)](https://man7.org/linux/man-pages/man2/umask.2.html) — Kernel documentation for how umask is applied at file creation time, explaining why `touch` produces 644 by default.
