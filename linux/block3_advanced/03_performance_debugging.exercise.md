# Exercise: Performance Debugging

## Task 1 — Baseline system metrics

Create `~/perflab/`. Capture a performance baseline:

1. Run `vmstat 1 3` (3 snapshots) and save to `~/perflab/vmstat.txt`
2. Run `cat /proc/meminfo` and save to `~/perflab/meminfo.txt`
3. Run `cat /proc/vmstat` and save to `~/perflab/proc_vmstat.txt`

## Task 2 — strace a command

Use `strace` to trace the `ls /etc` command and capture the output:

```bash
strace -e trace=openat,read,close ls /etc 2> ~/perflab/strace_ls.txt
```

Note: `strace` output goes to stderr by default, hence `2>`.

Then use `strace -c ls /etc 2> ~/perflab/strace_summary.txt` to get a summary of syscall counts and time.

## Task 3 — lsof inspection

1. Start a background process: `sleep 600 &` and note its PID
2. Run `lsof -p <PID>` and save to `~/perflab/lsof_sleep.txt`
3. Run `lsof -i` and save to `~/perflab/lsof_network.txt`
4. Count how many file descriptors the current bash shell has open: `ls /proc/$$/fd | wc -l` → save to `~/perflab/shell_fd_count.txt`

## Task 4 — /proc process inspection

Pick any running process (find one with `pgrep -a bash | head -1` or use `$$` for your shell):

1. Save `/proc/$$/status` to `~/perflab/proc_status.txt`
2. Extract just the `VmRSS` (resident memory) line and save to `~/perflab/proc_mem.txt`
3. Count the number of open file descriptors: `ls /proc/$$/fd | wc -l` → save to `~/perflab/proc_fd_count.txt`
