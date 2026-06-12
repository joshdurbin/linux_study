# Exit Codes, Streams, and xargs

## Exit Codes

Every process exits with a **status code** between 0 and 255. Zero means success; any non-zero value means failure. The shell stores the last exit code in `$?`.

```bash
ls /etc
echo $?     # 0 — success

ls /nonexistent 2>/dev/null
echo $?     # 2 — no such file or directory

# true and false: commands that exit 0 or 1 and do nothing else
true;  echo $?    # 0
false; echo $?    # 1
```

`true` and `false` are useful in scripts for explicit pass/fail, as loop conditions, and as no-op placeholders.

### Signal Exits

A process killed by a signal exits with `128 + signal_number`:

| Cause | Exit Code |
|-------|-----------|
| Normal success | 0 |
| General error | 1 |
| Misuse of shell builtin | 2 |
| Killed by SIGTERM (15) | 143 |
| Killed by SIGKILL (9) | 137 |
| Killed by SIGINT (2) | 130 |

### set -e and set -o pipefail

```bash
set -e             # exit script on first non-zero exit code
set -o pipefail    # fail if any command in a pipeline fails
set -u             # treat unset variables as errors

# Combined idiom at the top of every robust script:
set -euo pipefail
```

Without `pipefail`, failures hidden inside pipelines go unnoticed:

```bash
false | true       # exits 0 — the failure from false is invisible
set -o pipefail
false | true       # now exits 1
```

## stderr vs stdout: Why Two Streams?

You already know FD 1 is stdout and FD 2 is stderr. The design intent matters: **tools write errors to stderr so pipelines only process clean output**.

```bash
# stderr prints to terminal; stdout flows through the pipe
find /etc -name "*.conf" 2>/dev/null | grep "ssh"

# Capture stdout; let stderr reach the terminal
output=$(ls /nonexistent 2>/dev/null)
echo "Got: '$output'"    # empty — ls wrote nothing to stdout

# Capture each stream separately
ls /etc /nonexistent 1>out.txt 2>err.txt

# Capture stderr into a variable (redirect stderr to stdout, suppress stdout)
errors=$(ls /nonexistent 2>&1 >/dev/null)
echo "Captured: $errors"
```

### Writing to stderr from a Script

```bash
echo "Error: file not found" >&2        # redirect stdout to stderr
echo "Error: file not found" > /dev/stderr   # equivalent

# Idiomatic error-and-exit function:
die() {
    echo "ERROR: $1" >&2
    exit 1
}

die "config file missing"
```

### /dev/fd — File Descriptors as Paths

Linux exposes every open file descriptor as a path under `/dev/fd/` (also `/proc/self/fd/`):

```bash
ls -la /dev/fd/
# /dev/fd/0 → stdin
# /dev/fd/1 → stdout
# /dev/fd/2 → stderr

echo "hello" > /dev/fd/1    # same as writing to stdout
echo "error" > /dev/fd/2    # same as writing to stderr
```

Process substitution (`<(cmd)`) uses `/dev/fd/` internally — the shell creates a pipe, gives it a path like `/dev/fd/63`, and passes that path to the outer command.

## xargs — Build Commands from stdin

`xargs` reads tokens from stdin and passes them as arguments to a command. It bridges tools that produce output lists with tools that expect file arguments.

```bash
# Basic: pass all stdin tokens as arguments to one command invocation
echo "file1 file2 file3" | xargs touch

# -n: limit arguments per invocation
echo "a b c d e" | xargs -n 2 echo    # runs echo twice: "a b", then "c d e"

# -I{}: substitute each line into a placeholder
find . -name "*.log" | xargs -I{} cp {} /backup/

# -P: parallel execution
find . -name "*.gz" | xargs -P 4 -I{} gunzip {}
```

### xargs vs Command Substitution

```bash
# Command substitution can hit ARG_MAX (~2MB) with large file lists
rm $(cat filenames.txt)          # may fail: "Argument list too long"

# xargs batches arguments automatically — handles any list size
cat filenames.txt | xargs rm
```

### Null-Delimited Input (Safe for Filenames with Spaces)

```bash
# Default: split on whitespace — breaks on "my file.txt"
find . -name "*.txt" | xargs ls        # fails on spaces in names

# -print0 / -0: use null bytes as delimiter
find . -name "*.txt" -print0 | xargs -0 ls    # safe
```

### Practical Patterns

```bash
# grep across many files, find which ones match
find . -name "*.conf" | xargs grep -l "timeout"

# Count total lines across a file set
find . -name "*.py" | xargs wc -l | tail -1

# Batch delete files older than 7 days
find /tmp -mtime +7 | xargs rm -f

# Check all files in a manifest exist
cat manifest.txt | xargs ls -la
```

## Further Reading

- [man7.org — pipe(2)](https://man7.org/linux/man-pages/man2/pipe.2.html) — Kernel pipe semantics: buffer capacity (65,536 bytes by default), blocking rules, and SIGPIPE when the read end is closed.
- [man7.org — dup2(2)](https://man7.org/linux/man-pages/man2/dup2.2.html) — The syscall behind `2>&1`; explains how file descriptor duplication works and why redirect order matters.
- [GNU Coreutils Manual — xargs](https://www.gnu.org/software/coreutils/manual/coreutils.html) — Full reference for `xargs` flags including `-P` parallel execution, `-0` null-delimiter, and `-I{}` substitution.
- [POSIX — Exit Status](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_08_02) — The POSIX specification for exit status conventions, including signal-death encoding and the `set -e` semantics.
- [GNU Bash Manual — Pipelines](https://www.gnu.org/software/bash/manual/bash.html#Pipelines) — Covers `pipefail`, `lastpipe`, and how bash propagates exit codes through pipeline stages.
