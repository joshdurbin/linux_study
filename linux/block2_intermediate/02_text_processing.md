# Text Processing

The Unix philosophy shines with text: small tools (`awk`, `sed`, `cut`, `sort`, `uniq`) each do one thing well and compose via pipes into powerful data pipelines.

## awk — Field-Oriented Processing

`awk` reads input line by line, splits each into fields (`$1`, `$2`, ...), and runs a program for each line.

```bash
# Print specific field
awk '{print $1}' file.txt           # first field (default delimiter: whitespace)
awk -F: '{print $1}' /etc/passwd    # colon-delimited: usernames
awk -F, '{print $2}' data.csv       # CSV second column

# Patterns
awk '/error/ {print}' log.txt        # print lines matching /error/
awk '$3 > 100 {print $1, $3}' data   # conditional: print if field 3 > 100
awk 'NR==5' file                     # print line number 5
awk 'NR>=3 && NR<=7' file            # print lines 3-7

# Built-in variables
# NR  = current record (line) number
# NF  = number of fields in current line
# FS  = field separator (set with -F or in BEGIN)
# OFS = output field separator

awk '{print NR, $0}' file            # number every line
awk '{print NF, $0}' file            # field count per line

# BEGIN and END blocks
awk 'BEGIN {sum=0} {sum+=$2} END {print "Total:", sum}' data
awk 'BEGIN {print "START"} {print} END {print "END"}' file

# Multiple field separator
awk -F'[,:]' '{print $1}' mixed.txt
```

## sed — Stream Editor

`sed` applies edits to each line of input without opening a full editor.

```bash
# Substitution
sed 's/old/new/' file           # replace first match per line
sed 's/old/new/g' file          # replace all matches per line (global)
sed 's/old/new/gi' file         # global + case-insensitive
sed 's/old/new/2' file          # replace 2nd match only

# In-place editing
sed -i 's/http:/https:/g' urls.txt       # edit file in place
sed -i.bak 's/foo/bar/g' config.txt      # in-place with .bak backup

# Delete lines
sed '/pattern/d' file           # delete matching lines
sed '3d' file                   # delete line 3
sed '3,7d' file                 # delete lines 3-7

# Print (with -n to suppress default)
sed -n '5p' file                # print only line 5
sed -n '5,10p' file             # print lines 5-10
sed -n '/START/,/END/p' file    # print between patterns

# Insert / append
sed '3i\New line before line 3' file    # insert before line 3
sed '3a\New line after line 3' file     # append after line 3
sed '$a\Last line' file                 # append at end of file

# Address ranges
sed '/BEGIN/,/END/d' file        # delete from BEGIN to END pattern
```

## cut — Extract Fields/Characters

```bash
cut -d: -f1 /etc/passwd           # field 1, colon separator
cut -d, -f1,3 data.csv            # fields 1 and 3
cut -d: -f1-3 /etc/passwd         # fields 1 through 3
cut -c1-10 file.txt               # first 10 characters per line
cut -c5- file.txt                 # from character 5 to end
```

## sort — Sort Lines

```bash
sort file.txt                     # lexicographic sort
sort -r file.txt                  # reverse
sort -n numbers.txt               # numeric sort
sort -k2 file.txt                 # sort by field 2 (whitespace-delimited)
sort -k2,2n -k1,1 file            # numeric by field 2, then by field 1
sort -t: -k3,3n /etc/passwd       # sort passwd by UID (field 3)
sort -u file.txt                  # sort and remove duplicates
```

## uniq — Filter Duplicate Lines

```bash
sort file | uniq                  # remove duplicate adjacent lines (sort first!)
sort file | uniq -c               # count occurrences
sort file | uniq -d               # print only duplicate lines
sort file | uniq -u               # print only unique (non-duplicate) lines
```

## wc — Count Lines/Words/Bytes

```bash
wc file.txt                      # lines  words  bytes
wc -l file.txt                   # lines only
wc -w file.txt                   # words only
wc -c file.txt                   # bytes
ls /etc | wc -l                  # count files
```

## Practical Pipelines

```bash
# Top 10 most common words in a file
tr -s ' ' '\n' < file.txt | sort | uniq -c | sort -rn | head -10

# Find most disk-using files
du -ah /var | sort -rh | head -20

# Count occurrences of each HTTP status code in a log
awk '{print $9}' access.log | sort | uniq -c | sort -rn

# Extract unique IPs from logs
grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' access.log | sort -u
```

## Further Reading

- [GNU awk (gawk) Manual](https://www.gnu.org/software/gawk/manual/gawk.html) — The complete awk reference: all built-in variables, functions, patterns, `BEGIN`/`END` blocks, and gawk extensions like `OFMT` and `getline`.
- [GNU sed Manual](https://www.gnu.org/software/sed/manual/sed.html) — Full sed reference covering address ranges, branch/label (`b`, `t`), hold space (`h`, `H`, `g`, `G`), and multi-line patterns.
- [man7.org — regex(7)](https://man7.org/linux/man-pages/man7/regex.7.html) — POSIX basic and extended regular expression syntax reference, applicable to `grep`, `sed`, `awk`, and `find -regex`.
- [Julia Evans — The Actual AWK Tutorial](https://jvns.ca/blog/2018/03/28/the-actual-awk-tutorial/) — Hands-on introduction to awk patterns, field splitting, and real log-parsing use cases written for those who find the manual dense.
- [The Linux Command Line — Text Processing](https://linuxcommand.org/tlcl.php) — Chapters 20–21 cover `sort`, `uniq`, `cut`, `paste`, and `join` with realistic pipeline examples.
