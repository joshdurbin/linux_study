# strace Deep Dive — Exercises

Complete these tasks. Record findings in `~/practice/strace_analysis.txt`.

## Setup

```bash
mkdir -p ~/practice
```

## Task 1 — Syscall summary with -c

Run a syscall count summary for `ls`:

```bash
echo "=== strace -c ls ===" >> ~/practice/strace_analysis.txt
strace -c ls /etc 2>> ~/practice/strace_analysis.txt
```

After running, look at the output. Which syscall took the most total time? Which was called most often? Add a comment:

```bash
echo "# Most-called syscall: <name>, most time spent in: <name>" >> ~/practice/strace_analysis.txt
```

## Task 2 — Trace file opens

Capture every `openat` call made by `ls /etc`, filtering for just the filename argument:

```bash
echo "=== openat calls by ls /etc ===" >> ~/practice/strace_analysis.txt
strace -e trace=openat -s 256 ls /etc 2>&1 | head -30 >> ~/practice/strace_analysis.txt
```

How many library/config files does `ls` open before doing any real work?

## Task 3 — Time each syscall with -T

```bash
echo "=== strace -T timing ===" >> ~/practice/strace_analysis.txt
strace -T -e trace=openat ls /usr/bin 2>&1 | sort -t'<' -k2 -rn | head -10 >> ~/practice/strace_analysis.txt
```

The `<X.XXXXXX>` at the end of each line is the time spent. Which call was slowest?

## Task 4 — Find ENOENT errors

Programs often silently try paths that don't exist. Capture error calls:

```bash
echo "=== ENOENT errors from ls ===" >> ~/practice/strace_analysis.txt
strace -e openat -s 256 ls 2>&1 | grep ENOENT | head -20 >> ~/practice/strace_analysis.txt
echo "# Number of ENOENT: $(strace -e openat ls 2>&1 | grep -c ENOENT)" >> ~/practice/strace_analysis.txt
```

## Task 5 — Trace a shell command with -f (follow forks)

```bash
echo "=== strace -f -c bash -c 'echo hello' ===" >> ~/practice/strace_analysis.txt
strace -f -c bash -c 'echo hello' 2>> ~/practice/strace_analysis.txt
```

The `-f` flag follows child processes. Note how many more syscalls appear compared to tracing `ls` directly.

## Verification

```bash
cat ~/practice/strace_analysis.txt
```
