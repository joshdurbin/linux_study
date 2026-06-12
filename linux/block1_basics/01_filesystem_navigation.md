# Filesystem Navigation

The Linux filesystem is a single tree rooted at `/`. Everything — devices, network mounts, virtual files — lives somewhere under that root. Understanding how to move around and inspect that tree is the foundation of everything else.

## pwd — Print Working Directory

```bash
pwd              # print current directory
pwd -P           # resolve symlinks, show physical path
```

Your shell always has a "current directory." `pwd` tells you exactly where you are.

## ls — List Directory Contents

```bash
ls               # list current directory
ls /etc          # list a specific directory
ls -l            # long format: permissions, owner, size, date
ls -a            # include hidden files (dot-files)
ls -la           # long format + hidden files (most common combo)
ls -lh           # human-readable sizes (KB, MB, GB)
ls -lt           # sort by modification time, newest first
ls -lR           # recursive listing
ls -1            # one file per line
ls --color=auto  # colorize output (usually default)
```

The long-format columns: `permissions  links  owner  group  size  date  name`

## cd — Change Directory

```bash
cd /etc          # absolute path (starts from root)
cd Documents     # relative path (from current directory)
cd ..            # go up one level
cd ../..         # go up two levels
cd ~             # go to home directory
cd -             # go to previous directory (very useful!)
cd               # no argument = go home
```

## tree — Visual Directory Tree

```bash
tree             # show full tree from current directory
tree /etc        # tree from a specific path
tree -L 2        # limit depth to 2 levels
tree -a          # include hidden files
tree -d          # directories only
tree -h          # human-readable file sizes
```

`tree` is not always installed; use `apt install tree` if missing.

## du — Disk Usage

```bash
du               # disk usage of current directory (recursive)
du -h            # human-readable sizes
du -sh *         # summarize each item in current directory
du -sh /var/log  # how much space does /var/log use?
du -h --max-depth=1 /var  # one level deep
du -a            # show individual files too
```

## find — Search by Path/Name

```bash
find /home -name "*.txt"         # find .txt files under /home
find . -name "config.yaml"       # find in current directory
find /etc -type f                # files only (not directories)
find /etc -type d                # directories only
find . -name "*.log" -type f     # combine: .log files only
find / -name "passwd" 2>/dev/null  # suppress permission errors
find . -newer reference.txt      # files newer than reference.txt
find . -size +1M                 # files larger than 1 MB
```

## Key Paths to Know

| Path | Contents |
|------|----------|
| `/` | Filesystem root |
| `/home` | User home directories |
| `/etc` | Configuration files |
| `/var` | Variable data (logs, databases) |
| `/tmp` | Temporary files (cleared on reboot) |
| `/usr/bin` | User-installed executables |
| `/bin`, `/sbin` | System binaries |
| `/proc` | Virtual filesystem: kernel/process info |
| `/dev` | Device files |

## Tips

- Tab completion is your best friend. Type part of a path, hit Tab.
- `cd -` to bounce between two directories is incredibly useful.
- Use `ls -lah` as your default; the `a` and `h` flags rarely hurt.

## Further Reading

- [Filesystem Hierarchy Standard (FHS)](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html) — The official standard defining what every top-level directory (`/usr`, `/var`, `/etc`, `/tmp`) is for and what belongs there.
- [GNU Coreutils Manual — Disk usage](https://www.gnu.org/software/coreutils/manual/coreutils.html#du-invocation) — Full reference for `du` flags including `--max-depth`, `--apparent-size`, and the difference between blocks and bytes.
- [The Linux Command Line — Part 1: Learning the Shell](https://linuxcommand.org/tlcl.php) — Free book; chapters 1–4 cover navigation, `ls`, and the filesystem in depth with exercises.
- [man7.org — find(1)](https://man7.org/linux/man-pages/man1/find.1.html) — Complete reference for `find` expressions, `-exec`, `-print0`, and optimisation options used in filesystem searches.
- [man7.org — stat(2)](https://man7.org/linux/man-pages/man2/stat.2.html) — Defines `struct stat`: every inode field that `ls -l`, `du`, and `find` read from the kernel.
- [Arch Wiki — File system](https://wiki.archlinux.org/title/File_systems) — Comprehensive overview of Linux filesystem types, mounting, and how the VFS layer presents a unified tree.
