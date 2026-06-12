# Text Search

Searching for text patterns and files is a core Linux skill. `grep` searches inside files; `find` searches the filesystem by name/type/attributes; `locate` provides a fast indexed search.

## grep — Search File Contents

```bash
grep "pattern" file.txt          # basic search
grep -i "pattern" file.txt       # case-insensitive
grep -n "pattern" file.txt       # show line numbers
grep -r "pattern" /etc/          # recursive search through directory
grep -l "pattern" /etc/*.conf    # list only filenames, not matches
grep -L "pattern" /etc/*.conf    # list files that do NOT match
grep -c "pattern" file.txt       # count matching lines
grep -v "pattern" file.txt       # invert: show non-matching lines
grep -w "word" file.txt          # match whole word only
grep -A 3 "pattern" file.txt     # 3 lines of context After match
grep -B 3 "pattern" file.txt     # 3 lines Before match
grep -C 3 "pattern" file.txt     # 3 lines each side (Context)
```

### Extended Regex with -E (or egrep)

```bash
grep -E "error|warning" logfile      # OR pattern
grep -E "^[0-9]{4}-" dates.txt       # starts with 4 digits then dash
grep -E "\.conf$" list.txt           # ends with .conf
grep -E "(GET|POST) /api" access.log # match HTTP methods
grep -rn "TODO\|FIXME" ./src/        # find code comments (basic regex OR)
```

### Common Patterns

```bash
# Find lines with IP addresses
grep -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" file

# Search compressed files
zgrep "pattern" file.gz

# Case-insensitive recursive, show filenames
grep -ril "password" /etc/

# Exclude binary files
grep -r --include="*.py" "import os" ./
```

## find — Search Filesystem

```bash
find /path -name "filename"          # exact name match
find /path -name "*.log"             # glob pattern
find /path -iname "readme*"          # case-insensitive name
find /path -type f                   # files only
find /path -type d                   # directories only
find /path -type l                   # symlinks only
find /path -size +10M                # larger than 10 MB
find /path -size -1k                 # smaller than 1 KB
find /path -mtime -7                 # modified in last 7 days
find /path -mtime +30                # not modified in 30+ days
find /path -user root                # owned by root
find /path -perm 644                 # exact permissions
find /path -perm /u+s                # setuid bit set
```

### find with -exec

```bash
find /tmp -name "*.tmp" -exec rm {} \;       # delete matching files
find . -name "*.py" -exec grep -l "TODO" {} \;  # grep inside found files
find . -type f -exec chmod 644 {} \;         # batch chmod
find . -name "*.log" -exec ls -lh {} +       # + batches args (faster than \;)
```

### find with -print0 and xargs

```bash
# Safe handling of filenames with spaces
find . -name "*.txt" -print0 | xargs -0 grep "pattern"
```

## locate — Fast Indexed Search

```bash
locate nginx.conf          # find by name (searches index, not disk)
locate -i readme           # case-insensitive
locate -r "\.conf$"        # regex pattern
locate -c "*.py"           # count matches only
sudo updatedb              # refresh the index (usually runs via cron)
```

`locate` is much faster than `find` but searches an index that may be hours old. Use `find` when you need real-time results.

## which, whereis, type

```bash
which python3              # full path of executable in PATH
which -a python3           # all matches in PATH
whereis ls                 # binary, source, and man page locations
type cd                    # identifies builtins vs executables vs aliases
type -a python3            # all matches including aliases/functions

## Further Reading

- [GNU grep Manual](https://www.gnu.org/software/grep/manual/) — Complete reference for every grep flag, including `--include`/`--exclude` glob filters, `-P` Perl regex, and binary-file handling.
- [man7.org — regex(7)](https://man7.org/linux/man-pages/man7/regex.7.html) — The POSIX spec for basic and extended regular expression syntax that `grep -E` and `find -regex` both follow.
- [GNU find Manual](https://www.gnu.org/software/findutils/manual/find.html) — Full documentation for `find` predicates, `-exec`, `-print0`, and the optimisation levels (`-O1`/`-O2`/`-O3`).
- [man7.org — find(1)](https://man7.org/linux/man-pages/man1/find.1.html) — Online man page covering every `find` primary expression and operator with concise syntax reference.
- [The Linux Command Line — Searching for Files](https://linuxcommand.org/tlcl.php) — Chapter 17 covers `find` and `locate` with real-world search patterns and `-exec` examples.
