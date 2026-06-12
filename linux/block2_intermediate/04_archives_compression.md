# Archives and Compression

Packaging files into archives and compressing them are routine tasks — for backups, deployments, and data transfer. `tar` is the workhorse; `gzip`, `bzip2`, and `xz` provide compression.

## tar — Tape Archive

`tar` combines multiple files into a single archive (optionally compressed).

### Creating Archives

```bash
tar -cf archive.tar files/          # create archive (no compression)
tar -czf archive.tar.gz files/      # create + gzip compress
tar -cjf archive.tar.bz2 files/     # create + bzip2 compress
tar -cJf archive.tar.xz files/      # create + xz compress (best ratio)
tar -czf archive.tar.gz file1 file2 dir/  # multiple sources
tar -czf backup.tar.gz --exclude='*.log' /etc/  # exclude pattern
```

### Extracting Archives

```bash
tar -xf archive.tar                 # extract (auto-detect compression)
tar -xzf archive.tar.gz             # extract gzip
tar -xjf archive.tar.bz2            # extract bzip2
tar -xJf archive.tar.xz             # extract xz
tar -xf archive.tar -C /tmp/        # extract to specific directory
tar -xf archive.tar specific/file   # extract single file
```

### Listing Contents

```bash
tar -tf archive.tar                 # list contents
tar -tzf archive.tar.gz             # list gzip archive
tar -tvf archive.tar                # verbose: permissions, owner, size
```

### Flags Reference

| Flag | Meaning |
|------|---------|
| `-c` | Create |
| `-x` | Extract |
| `-t` | List |
| `-f` | Filename follows |
| `-z` | gzip |
| `-j` | bzip2 |
| `-J` | xz |
| `-v` | Verbose |
| `-C dir` | Change to dir |
| `-p` | Preserve permissions |
| `--strip-components=N` | Strip N leading path components |

## gzip / gunzip

```bash
gzip file.txt               # compress: creates file.txt.gz, removes original
gzip -k file.txt            # keep original
gzip -d file.txt.gz         # decompress (same as gunzip)
gunzip file.txt.gz          # decompress
gzip -l file.gz             # list compression ratio and sizes
gzip -9 file.txt            # maximum compression
gzip -1 file.txt            # fastest (least compression)
zcat file.gz                # print compressed file without extracting
zgrep "pattern" file.gz     # grep inside compressed file
```

## bzip2

```bash
bzip2 file.txt              # compress to file.txt.bz2
bunzip2 file.txt.bz2        # decompress
bzip2 -k file.txt           # keep original
bzcat file.bz2              # print without extracting
```

bzip2 generally compresses better than gzip but is slower.

## zip / unzip

```bash
zip archive.zip file1 file2     # create zip
zip -r archive.zip directory/   # recursive
zip -e secure.zip file.txt      # encrypt with password
unzip archive.zip               # extract
unzip archive.zip -d /tmp/      # extract to directory
unzip -l archive.zip            # list contents
unzip -p archive.zip file.txt   # print file to stdout
```

`zip` preserves Windows-compatible paths; `tar.gz` is standard on Linux.

## rsync — Efficient File Sync

```bash
rsync -av src/ dest/                       # archive mode, verbose
rsync -avz src/ user@host:dest/            # to remote host, compress
rsync -avz --delete src/ dest/             # mirror: delete extras in dest
rsync -avzn src/ dest/                     # dry run (show what would change)
rsync --exclude='*.log' src/ dest/         # exclude pattern
rsync -avz --progress src/ dest/           # show transfer progress
```

`-a` (archive) = `-rlptgoD`: recursive, preserve symlinks, permissions, times, owner, group, devices.

## Practical Patterns

```bash
# Backup /etc with timestamp
tar -czf /backup/etc-$(date +%Y%m%d).tar.gz /etc/

# Extract and strip top-level directory
tar -xzf pkg.tar.gz --strip-components=1

# View a .gz log without extracting
zcat /var/log/syslog.1.gz | grep "error"

# Incremental rsync backup
rsync -avz --link-dest=/backup/prev /data/ /backup/$(date +%Y%m%d)/
```

## Further Reading

- [GNU tar Manual](https://www.gnu.org/software/tar/manual/tar.html) — Complete tar reference including `--listed-incremental` for true incremental backups, `--transform`, and sparse-file handling.
- [man7.org — gzip(1)](https://man7.org/linux/man-pages/man1/gzip.1.html) — Full gzip flag reference including the `-1`–`-9` compression levels, `zcat`, and the DEFLATE format.
- [rsync Official Documentation](https://rsync.samba.org/documentation.html) — The rsync project's own documentation including the rsync algorithm paper explaining delta-transfer and `--link-dest` hardlink backups.
- [The Linux Command Line — Archiving and Backup](https://linuxcommand.org/tlcl.php) — Chapter 18 covers `tar`, `gzip`, `bzip2`, and `rsync` with practical backup and deployment workflow examples.
- [Arch Wiki — Archiving and compression](https://wiki.archlinux.org/title/Archiving_and_compression) — Comparison table of formats (tar, zip, 7z, zstd) with compression ratios, speed, and use-case guidance.
