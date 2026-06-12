# rsync — Efficient File Synchronization

rsync transfers only the differences between source and destination, making it far faster than `cp` or `scp` for large datasets or repeated syncs. It's the standard tool for backups, deployments, and mirrors.

## Basic Syntax

```bash
rsync [options] source destination
```

**Trailing slash on source matters:**
```bash
rsync -av src/  dst/   # sync the CONTENTS of src into dst
rsync -av src   dst/   # sync src directory itself into dst (creates dst/src/)
```

## Core Flags

| Flag | Meaning |
|------|---------|
| `-a` | Archive mode: `-rlptgoD` (recursive, preserve symlinks, permissions, timestamps, group, owner, devices) |
| `-v` | Verbose — show transferred files |
| `-z` | Compress during transfer (useful on slow links) |
| `-n` / `--dry-run` | Show what would be transferred without doing it |
| `-P` | `--progress --partial` — show progress, resume interrupted transfers |
| `--delete` | Delete files in destination that don't exist in source |
| `-e ssh` | Use SSH as transport |
| `--exclude` | Exclude a pattern |
| `--include` | Include a pattern (evaluated before excludes) |
| `--checksum` | Use checksum instead of size+mtime to determine changes |
| `--bwlimit=KB` | Limit bandwidth in KB/s |
| `--stats` | Print transfer statistics |

## Local Sync

```bash
# Sync a directory (dry run first — always)
rsync -avn ~/src/ ~/dst/

# Perform the sync
rsync -av ~/src/ ~/dst/

# Mirror: dst matches src exactly (delete extras)
rsync -av --delete ~/src/ ~/dst/
```

## Remote Sync over SSH

```bash
# Local → remote
rsync -avz ./deploy/ user@server:/var/www/app/

# Remote → local (backup)
rsync -avz user@server:/var/backups/ ./local-backup/

# Use a non-standard SSH port
rsync -avz -e "ssh -p 2222" ./src/ user@server:/dst/

# Use a specific SSH key
rsync -avz -e "ssh -i ~/.ssh/deploy_key" ./src/ user@server:/dst/
```

## Exclude Patterns

```bash
# Exclude a single directory
rsync -av --exclude='.git' ./src/ ./dst/

# Multiple excludes
rsync -av --exclude='.git' --exclude='*.log' --exclude='node_modules/' ./src/ ./dst/

# Exclude file (one pattern per line)
rsync -av --exclude-from='.rsyncignore' ./src/ ./dst/

# Exclude all .log files but include error.log
rsync -av --include='error.log' --exclude='*.log' ./src/ ./dst/
```

## Backup Patterns

```bash
# Daily backup with hardlinks (efficient snapshot)
rsync -av --delete --link-dest=../backup-yesterday/ ~/data/ ~/backup-today/

# Backup with timestamp
DEST=~/backups/$(date +%Y-%m-%d)
rsync -av --link-dest=$(ls -td ~/backups/*/ | head -1) ~/data/ "$DEST/"
```

## Transfer Progress and Stats

```bash
rsync -avP --stats large_file.tar.gz user@host:/tmp/
# Shows:
# Number of files, transferred, total size
# Speedup ratio (how much smaller transfer was than total data)
```

## rsync Daemon Mode

For high-frequency or anonymous syncs without SSH:

```bash
# /etc/rsyncd.conf
[mymodule]
    path = /var/data
    read only = yes
    comment = Data mirror

# Client connects via rsync:// URL
rsync rsync://server/mymodule/ ./local/
```

## Common Patterns

```bash
# Deploy a web app (dry run first)
rsync -avn --delete --exclude='.env' --exclude='node_modules/' \
  ./dist/ user@prod:/var/www/app/

# Pull database backup
rsync -avz --progress user@db:/var/backups/db.sql.gz ./

# Sync between two remote servers (through local machine)
rsync -avz user@source:/data/ user@dest:/data/
# Note: traffic flows through your machine

# Mirror a directory to S3-compatible (via rclone, not rsync, but similar flags)
```

## Further Reading

- [rsync Official Documentation](https://rsync.samba.org/documentation.html) — The rsync project's own docs including the complete options reference, filter rules, daemon mode, and the `rsyncd.conf` format.
- [man7.org — rsync(1)](https://man7.org/linux/man-pages/man1/rsync.1.html) — Full man page covering every flag, filter rule syntax (`--include`/`--exclude`/`--filter`), and `--link-dest` hardlink backup semantics.
- [The rsync Algorithm (technical report)](https://rsync.samba.org/tech_report/) — The original paper by Andrew Tridgell explaining the rolling checksum delta-transfer algorithm that makes rsync efficient for large files.
- [Arch Wiki — rsync](https://wiki.archlinux.org/title/Rsync) — Practical guide to rsync for backups, snapshots with `--link-dest`, and using rsync as a reliable `cp`/`scp` replacement.
