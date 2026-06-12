# I/O Redirection

Every Unix process has three standard file descriptors: stdin (0), stdout (1), and stderr (2). Redirection lets you connect these to files, other processes, and devices.

## Standard Streams

| FD | Name | Default | Symbol |
|----|------|---------|--------|
| 0 | stdin | keyboard | `<` |
| 1 | stdout | terminal | `>` |
| 2 | stderr | terminal | `2>` |

## Output Redirection

```bash
echo "hello" > file.txt        # write stdout to file (overwrite)
echo "world" >> file.txt       # append stdout to file
ls /noexist 2> err.txt         # write stderr to file
ls /noexist 2>> err.txt        # append stderr to file

# Redirect both stdout and stderr
ls /etc /noexist > out.txt 2>&1       # stderr to same fd as stdout
ls /etc /noexist &> out.txt           # bash shorthand for same thing
ls /etc /noexist 2>&1 | less         # pipe both streams to less

# Silence output
command > /dev/null              # discard stdout
command 2> /dev/null             # discard stderr
command > /dev/null 2>&1         # discard everything
```

**Order matters**: `2>&1 > file` is wrong; `> file 2>&1` is correct.

## Input Redirection

```bash
wc -l < file.txt               # feed file to stdin
sort < unsorted.txt             # sort reads from file
mysql db < schema.sql           # feed SQL to mysql
```

## Pipes

```bash
cmd1 | cmd2                    # stdout of cmd1 → stdin of cmd2
ls -la | grep ".txt"           # filter ls output
ps aux | sort -k3 -rn | head   # top CPU-using processes
cat /etc/passwd | cut -d: -f1 | sort  # sorted usernames
```

Pipes are a key Unix philosophy: small tools chained together.

## tee — Split Output

```bash
command | tee file.txt          # write to file AND show on terminal
command | tee -a file.txt       # append to file AND show on terminal
command | tee file.txt | grep "pattern"  # filter what's displayed
```

`tee` is invaluable for logging while still seeing output.

## /dev/null and /dev/zero

```bash
/dev/null     # write = discard; read = EOF immediately
/dev/zero     # read = infinite stream of null bytes

# Examples
command > /dev/null 2>&1       # completely silence a command
dd if=/dev/zero of=bigfile bs=1M count=10  # create a 10MB zero-filled file
```

## Here Documents (heredoc)

```bash
cat << EOF
Line 1
Line 2
EOF

# Feed multiple lines to a command
mysql -u root << EOF
CREATE DATABASE test;
USE test;
EOF

# With variable expansion disabled
cat << 'EOF'
No $VARIABLE expansion here
EOF
```

## Here Strings

```bash
grep "pattern" <<< "some string to search"
base64 -d <<< "aGVsbG8="
wc -w <<< "count these words"
```

## Process Substitution

```bash
diff <(ls dir1/) <(ls dir2/)         # diff two command outputs as files
wc -l <(find . -name "*.py")         # count files without temp file
cat <(echo "header") file.txt        # prepend a line
sort -m <(sort file1) <(sort file2)  # merge two sorted streams
```

Process substitution `<(cmd)` presents the output of `cmd` as a virtual file. It uses `/dev/fd/` internally.

## Practical Patterns

```bash
# Capture stdout and stderr separately
command 1>stdout.txt 2>stderr.txt

# Log and display simultaneously
./build.sh 2>&1 | tee build.log

# Read from command output like a file
while read line; do
  echo "Got: $line"
done < <(find . -name "*.conf")
```

## Further Reading

- [man7.org — pipe(2)](https://man7.org/linux/man-pages/man2/pipe.2.html) — Defines the kernel pipe primitive that every `|` in the shell creates; covers the 65 KB buffer, blocking rules, and SIGPIPE.
- [man7.org — open(2)](https://man7.org/linux/man-pages/man2/open.2.html) — Documents `O_TRUNC` and `O_APPEND` flags, explaining at the syscall level why `>` overwrites while `>>` appends.
- [man7.org — dup2(2)](https://man7.org/linux/man-pages/man2/dup2.2.html) — The syscall behind `2>&1`; explains how the shell wires file descriptors before exec and why redirection order matters.
- [GNU Bash Manual — Redirections](https://www.gnu.org/software/bash/manual/bash.html#Redirections) — Authoritative reference for all bash redirection operators including here-documents, here-strings, and process substitution.
- [Julia Evans — A Peek at the Linux Kernel with ftrace](https://jvns.ca/blog/2022/03/08/a-peek-at-the-linux-kernel-with-ftrace/) — Shows how tools like `cat` and pipes interact with kernel I/O paths, giving intuition for buffering and performance.
