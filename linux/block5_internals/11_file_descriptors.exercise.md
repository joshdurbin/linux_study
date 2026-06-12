# Exercise: File Descriptors

## Tasks

1. **Inspect your shell's FD table**: List all open FDs for your current shell and what each points to:
   ```bash
   ls -la /proc/$$/fd > ~/practice/fd_table.txt
   for fd in 0 1 2 255; do
     target=$(readlink /proc/$$/fd/$fd 2>/dev/null || echo "not open")
     echo "FD $fd -> $target"
   done >> ~/practice/fd_table.txt
   ```

2. **fdinfo**: Read the position and flags for FD 1 (stdout):
   ```bash
   cat /proc/$$/fdinfo/1 > ~/practice/fd_info.txt
   ```

3. **dup2 in action**: Use strace to observe the dup2 call that happens during shell redirection:
   ```bash
   strace -e dup2,open,openat bash -c "echo hello > /tmp/fd_redir_test" 2>&1 \
     > ~/practice/fd_strace.txt
   cat ~/practice/fd_strace.txt | grep -E "(dup2|openat)"
   ```

4. **FD inheritance**: Demonstrate that child processes inherit FDs:
   ```bash
   # Open FD 5 pointing to a file, then spawn a child that can write to it
   exec 5>/tmp/fd_inherit_test
   echo "written via FD 5" >&5
   exec 5>&-  # close it
   cat /tmp/fd_inherit_test > ~/practice/fd_inherit.txt
   ```

5. **Limits**: Record the FD soft and hard limits:
   ```bash
   echo "soft: $(ulimit -n)" > ~/practice/fd_limits.txt
   echo "hard: $(ulimit -Hn)" >> ~/practice/fd_limits.txt
   grep "Open files" /proc/$$/limits >> ~/practice/fd_limits.txt
   ```

## Hints

- FD 255 in bash is a saved copy of stdin used for job control — it appears in most interactive shells
- `readlink /proc/$$/fd/N` tells you what resource the FD points to
- `strace -e dup2` filters to only show dup2 calls — cleaner than unfiltered strace output
