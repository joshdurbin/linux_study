# Exercise: Exploring /proc

## Setup

```bash
mkdir -p ~/practice
```

## Task 1: Read System Info from /proc

Run the following commands and observe the output:

```bash
cat /proc/version
cat /proc/uptime
cat /proc/loadavg
```

Answer these questions (write them down mentally or in a file):
- How long has the system been running?
- What are the three load average values?

## Task 2: Read /proc/meminfo and Save Notes

Read `/proc/meminfo` and save information about memory to a notes file:

```bash
grep -E "MemTotal|MemAvailable|SwapTotal|Cached:" /proc/meminfo > ~/practice/proc_notes.txt
cat ~/practice/proc_notes.txt
```

The file must exist with content showing memory stats.

## Task 3: Explore /proc/self

Examine your current shell process through `/proc/self`:

```bash
# Your current command line
cat /proc/self/cmdline | tr '\0' ' '
echo

# Your process status
cat /proc/self/status | head -15

# Your open file descriptors
ls -la /proc/self/fd

# Your current working directory
readlink /proc/self/cwd

# Your executable
readlink /proc/self/exe
```

## Task 4: Find a Running Process and Inspect It

Find the PID of the init/systemd process (PID 1) and inspect it:

```bash
cat /proc/1/cmdline | tr '\0' ' '
echo

# Check its status
cat /proc/1/status | grep -E "^(Name|Pid|State|VmRSS)"

# Count its open file descriptors
ls /proc/1/fd 2>/dev/null | wc -l
```

## Task 5: Read Memory Map of Current Shell

Look at how memory is laid out for your current process:

```bash
cat /proc/self/maps | head -20
```

Look for regions labeled `[stack]`, `[heap]`, and `[vdso]`. Note that each line shows:
- Address range
- Permissions (r/w/x/p or s)
- Offset, device, inode
- Mapping name (file or anonymous)

Append a note about what you found:
```bash
echo "Explored /proc/self/maps on $(date)" >> ~/practice/proc_notes.txt
echo "Stack found: $(grep '\[stack\]' /proc/self/maps)" >> ~/practice/proc_notes.txt
```

## Expected Outcome

- `~/practice/proc_notes.txt` exists and contains output from `/proc/meminfo`
- You can navigate `/proc/self/` and read process information without needing `ps` or `top`
