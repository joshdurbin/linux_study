# Viewing Files

Before editing or processing a file, you need to read it. Linux provides a spectrum of tools from quick full-dumps to paged navigation to binary inspection.

## cat — Concatenate and Print

```bash
cat file.txt             # print entire file to stdout
cat -n file.txt          # number every line
cat -A file.txt          # show non-printing chars (tabs as ^I, $ at EOL)
cat file1.txt file2.txt  # concatenate two files
cat > newfile.txt        # type content from stdin (Ctrl-D to end)
```

`cat` is best for small files. On large files, your terminal will flood.

## less — Paged Viewer (preferred)

```bash
less file.txt            # open file in pager
less +G file.txt         # open at end of file
less +/pattern file.txt  # open and search for pattern
```

Key bindings inside `less`:
| Key | Action |
|-----|--------|
| `Space` / `f` | Forward one page |
| `b` | Back one page |
| `/pattern` | Search forward |
| `n` / `N` | Next / previous match |
| `g` / `G` | Go to top / bottom |
| `q` | Quit |
| `-N` | Toggle line numbers |

## head and tail — First and Last Lines

```bash
head file.txt            # first 10 lines (default)
head -n 20 file.txt      # first 20 lines
head -c 100 file.txt     # first 100 bytes

tail file.txt            # last 10 lines
tail -n 30 file.txt      # last 30 lines
tail -f /var/log/syslog  # follow: print new lines as they're appended
tail -F logfile          # follow by name (reopens if file rotates)
```

`tail -f` is invaluable for watching log files in real time.

## wc — Word/Line/Byte Count

```bash
wc file.txt              # lines, words, bytes
wc -l file.txt           # line count only
wc -w file.txt           # word count only
wc -c file.txt           # byte count
wc -m file.txt           # character count (differs from -c for multibyte)
wc -l *.txt              # count lines in all .txt files
ls /etc | wc -l          # count files in /etc
```

## file — Identify File Type

```bash
file document.pdf        # identify by content (magic bytes), not extension
file /bin/ls             # ELF 64-bit LSB executable
file image.jpg           # JPEG image data
file archive.tar.gz      # gzip compressed data
file /dev/sda            # block special
file -b file.txt         # brief: no filename in output
```

`file` reads magic bytes — it works even when extensions are wrong or missing.

## hexdump — Inspect Binary Content

```bash
hexdump file             # hex + ASCII dump (default format)
hexdump -C file          # canonical hex+ASCII (most readable)
hexdump -C file | head   # first few lines (check file header)
xxd file                 # alternative with cleaner output
xxd -l 32 file           # first 32 bytes only
od -c file               # octal dump with char names
```

Use `hexdump -C` to inspect binary files, check magic bytes, or debug encoding issues.

## Practical Examples

```bash
# Check the shebang of a script
head -1 script.sh

# Watch a log file as new entries arrive
tail -f /var/log/auth.log

# Count number of users in /etc/passwd
wc -l /etc/passwd

# Check if a file is binary or text
file mydata

# Verify a PNG file's magic bytes (should start with 89 50 4e 47)
hexdump -C image.png | head -2

# Read a file page by page with line numbers
less -N largefile.txt
```

## Further Reading

- [GNU Coreutils Manual — cat, head, tail, wc](https://www.gnu.org/software/coreutils/manual/coreutils.html#cat-invocation) — Full option reference for each tool, including `cat -A` control characters, `tail -F` name-based following, and `wc -m` multibyte character counting.
- [man7.org — read(2)](https://man7.org/linux/man-pages/man2/read.2.html) — The kernel syscall that `cat` calls in a loop; clarifies buffering, partial reads, and why large files flood the terminal.
- [man7.org — inotify(7)](https://man7.org/linux/man-pages/man7/inotify.7.html) — The kernel event API that `tail -f` and `less +F` use to detect new file content without polling.
- [The Linux Command Line — Looking Around](https://linuxcommand.org/tlcl.php) — Chapter 3 covers `less` navigation in detail, including the key bindings and search modes used daily.
- [Arch Wiki — Core utilities](https://wiki.archlinux.org/title/Core_utilities) — Concise reference covering `cat`, `less`, `head`, `tail`, and `file` with common usage patterns and alternatives.
