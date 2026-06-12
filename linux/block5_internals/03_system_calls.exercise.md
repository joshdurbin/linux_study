# Exercise: System Calls and strace

## Setup

```bash
mkdir -p ~/practice
which strace || sudo apt-get install -y strace
```

## Task 1: Count Syscalls with strace -c

Run `strace -c` to get a syscall summary for a simple command:

```bash
strace -c ls /tmp 2>&1
```

Observe the output table. Which syscall took the most time? Which was called most often?

Save the output:
```bash
strace -c ls /tmp 2>&1 > ~/practice/strace_output.txt
cat ~/practice/strace_output.txt
```

## Task 2: Trace open() Calls

Trace only file-open related syscalls to see what `ls` reads at startup:

```bash
strace -e trace=openat ls /tmp 2>&1 | head -30
```

You'll see the dynamic linker opening shared libraries before `ls` even starts. Append to your output file:

```bash
echo "--- openat trace ---" >> ~/practice/strace_output.txt
strace -e trace=openat ls /tmp 2>&1 >> ~/practice/strace_output.txt
```

## Task 3: Trace a More Interesting Command

Trace `cat /proc/version` to see what syscalls a file read involves:

```bash
strace cat /proc/version 2>&1
```

Look for the sequence: `openat` → `fstat` → `fadvise64` → `read` → `write` → `close`

Add to your notes:
```bash
echo "--- cat /proc/version trace ---" >> ~/practice/strace_output.txt
strace -e trace=openat,read,write,close cat /proc/version 2>&1 >> ~/practice/strace_output.txt
```

## Task 4: View a Process's Current Syscall

Check what syscall your current shell is executing:

```bash
cat /proc/$$/syscall
```

The first number is the syscall number. To decode it:
```bash
# The 'wait' family of syscalls has numbers in the 200s+ range on x86-64
# Check the actual number against the table
ausyscall --dump 2>/dev/null | head -20 || grep -r "^#define __NR_" /usr/include/asm/unistd_64.h 2>/dev/null | head -20
```

## Task 5: Compare Syscall Counts Between Commands

Compare the syscall overhead of two similar commands:

```bash
strace -c echo "hello" 2>&1 | tail -5
strace -c bash -c 'echo "hello"' 2>&1 | tail -5
```

The second should have significantly more syscalls because bash itself loads many resources.

Append comparison notes:
```bash
echo "--- echo vs bash echo comparison ---" >> ~/practice/strace_output.txt
echo "Direct echo:" >> ~/practice/strace_output.txt
strace -c echo "hello" 2>&1 >> ~/practice/strace_output.txt
echo "Bash echo:" >> ~/practice/strace_output.txt
strace -c bash -c 'echo "hello"' 2>&1 >> ~/practice/strace_output.txt
```

## Expected Outcome

- `~/practice/strace_output.txt` exists and contains syscall summary data
- You can interpret strace -c output and filter by syscall type
- You understand the difference between a syscall number and its name
