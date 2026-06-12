# File Operations

Creating, copying, moving, and linking files are daily Linux tasks. This lesson covers the core file manipulation commands with their most useful flags.

## touch — Create Files / Update Timestamps

```bash
touch file.txt           # create empty file (or update timestamp if exists)
touch a.txt b.txt c.txt  # create multiple files
touch -t 202301010000 f  # set timestamp explicitly
```

## mkdir — Create Directories

```bash
mkdir mydir              # create a directory
mkdir -p a/b/c           # create nested dirs, no error if exists
mkdir -m 700 private     # create with specific permissions
```

## cp — Copy Files and Directories

```bash
cp source.txt dest.txt          # copy file
cp file.txt /tmp/               # copy to a directory
cp -r srcdir/ destdir/          # copy directory recursively
cp -p file.txt backup.txt       # preserve permissions, timestamps, owner
cp -u src dst                   # copy only if src is newer
cp -v file.txt /tmp/            # verbose: show what's being copied
cp -i file.txt dest.txt         # interactive: prompt before overwrite
```

## mv — Move / Rename Files

```bash
mv old.txt new.txt              # rename a file
mv file.txt /tmp/               # move to another directory
mv dir1/ /var/data/             # move a directory
mv -i src dst                   # prompt before overwriting
mv -v file.txt /tmp/            # verbose
mv -n src dst                   # never overwrite existing dest
```

`mv` on the same filesystem is instant (just updates directory entries). Cross-filesystem `mv` copies then deletes.

## rm — Remove Files and Directories

```bash
rm file.txt              # remove a file
rm -i file.txt           # prompt before removing
rm -f file.txt           # force (no error if not found, no prompts)
rm -r directory/         # remove directory recursively
rm -rf directory/        # force recursive remove (be careful!)
rm -v file.txt           # verbose
```

`rm` is permanent — there is no trash. Double-check before `rm -rf`.

## ln — Create Links

Hard links and soft (symbolic) links are different:

```bash
# Soft (symbolic) link — a pointer to a path
ln -s /etc/nginx/nginx.conf ~/nginx.conf   # symlink in home dir
ln -s /var/log logs                        # symlink to directory

# Hard link — another name for the same inode
ln original.txt hardlink.txt

# Check links
ls -la         # symlinks show as -> target
ls -i          # show inode numbers (hard links share inodes)
```

Symlinks can point to nonexistent targets (dangling). Hard links only work within a filesystem.

## stat — Detailed File Metadata

```bash
stat file.txt            # full metadata: inode, links, times, size
stat -c "%n %s %y" f     # custom format: name, size, mod time
stat /etc/passwd         # check owner, permissions, timestamps
```

`stat` shows three timestamps:
- **atime** — last accessed
- **mtime** — last modified (content)
- **ctime** — last changed (metadata or content)

## Practical Patterns

```bash
# Backup before editing
cp config.yaml config.yaml.bak

# Rename all .txt to .md in current dir
for f in *.txt; do mv "$f" "${f%.txt}.md"; done

# Remove files older than 7 days
find /tmp -mtime +7 -type f -delete

# Create a directory and immediately cd into it
mkdir -p /tmp/test && cd /tmp/test
```

## Further Reading

- [GNU Coreutils Manual — cp](https://www.gnu.org/software/coreutils/manual/coreutils.html#cp-invocation) — Full flag reference for `cp` including `-a`, `--reflink`, and sparse-file handling.
- [GNU Coreutils Manual — mv and ln](https://www.gnu.org/software/coreutils/manual/coreutils.html#mv-invocation) — Covers `mv` cross-filesystem semantics and `ln` hard-link vs symlink distinctions.
- [man7.org — stat(2)](https://man7.org/linux/man-pages/man2/stat.2.html) — Defines the `struct stat` fields that `stat`, `cp -p`, and `touch -t` all read and write.
- [man7.org — rename(2)](https://man7.org/linux/man-pages/man2/rename.2.html) — The kernel syscall behind `mv`; explains atomicity guarantees and the `EXDEV` cross-device error.
- [man7.org — link(2)](https://man7.org/linux/man-pages/man2/link.2.html) — Defines hard-link semantics: reference counting, same-filesystem restriction, and inode lifetime.
- [The Linux Command Line — Manipulating Files](https://linuxcommand.org/tlcl.php) — Chapter 4 walks through `cp`, `mv`, `rm`, and `ln` with practical examples and pitfall warnings.
