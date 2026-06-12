# Processes

A process is a running instance of a program. Linux gives every process a unique PID (process ID) and a rich set of tools to inspect and control them.

## ps — Process Snapshot

```bash
ps                    # your processes in current terminal
ps aux                # ALL processes, full format (BSD style)
ps -ef                # ALL processes, full format (POSIX style)
ps aux | grep nginx   # find a specific process
ps -p 1234            # info about a specific PID
ps --forest           # ASCII tree showing parent-child relationships
ps -o pid,ppid,cmd    # custom output columns
```

`ps aux` columns: `USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND`

STAT codes: `S` = sleeping, `R` = running, `Z` = zombie, `D` = uninterruptible sleep, `+` = foreground.

## top — Live Process Monitor

```bash
top                  # launch interactive process monitor
top -u alice         # show only alice's processes
top -p 1234,5678     # watch specific PIDs
top -n 1 -b          # batch mode: one snapshot, good for scripting
```

Key bindings in `top`:
| Key | Action |
|-----|--------|
| `q` | Quit |
| `k` | Kill a process (prompts for PID) |
| `r` | Renice (change priority) |
| `M` | Sort by memory |
| `P` | Sort by CPU |
| `1` | Toggle per-CPU stats |
| `u` | Filter by user |
| `h` | Help |

## Signals

Signals are software interrupts sent to processes:

| Signal | Number | Meaning |
|--------|--------|---------|
| SIGTERM | 15 | Polite termination request (default for `kill`) |
| SIGKILL | 9 | Force-kill immediately (cannot be caught) |
| SIGHUP | 1 | Hangup — reload config (for daemons) |
| SIGINT | 2 | Interrupt (Ctrl-C) |
| SIGSTOP | 19 | Pause process (cannot be caught) |
| SIGCONT | 18 | Continue paused process |

## kill and killall

```bash
kill 1234            # send SIGTERM to PID 1234
kill -9 1234         # send SIGKILL (force)
kill -SIGHUP 1234    # send SIGHUP
kill -l              # list all signal names

killall nginx        # kill all processes named nginx
killall -9 nginx     # force-kill all nginx
killall -HUP nginx   # send SIGHUP to all nginx (reload)
pkill -f "python script.py"  # kill by matching full command
```

## Job Control

```bash
command &            # run in background
Ctrl-Z               # suspend current foreground job
jobs                 # list background/suspended jobs
bg %1                # resume job 1 in background
fg %1                # bring job 1 to foreground
fg                   # bring most recent job to foreground
kill %1              # kill background job 1
```

`jobs` output: `[1]+ Running   sleep 100 &`
The `+` means "current job" (what `fg` acts on).

## nohup — Survive Terminal Closure

```bash
nohup long_script.sh &           # run immune to SIGHUP
nohup long_script.sh > out.log & # capture output
```

Without `nohup`, background processes receive SIGHUP when you log out and may terminate.

## pgrep and pstree

```bash
pgrep nginx               # list PIDs matching name
pgrep -u alice            # PIDs owned by alice
pgrep -a nginx            # PIDs with full command

pstree                    # visual process tree
pstree -p                 # include PIDs
pstree -u                 # include usernames
```

## Practical Patterns

```bash
# Find and kill a port-holding process
sudo lsof -i :8080        # who is using port 8080?
kill $(lsof -ti :8080)    # kill it

# Watch process CPU/mem over time
watch -n 1 'ps aux --sort=-%cpu | head -10'

# Check if a service is running
pgrep -x nginx > /dev/null && echo "running" || echo "stopped"
```

## Further Reading

- [man7.org — proc(5)](https://man7.org/linux/man-pages/man5/proc.5.html) — Documents every file under `/proc/[pid]/` that `ps` and `top` read for process state, memory maps, file descriptors, and CPU statistics.
- [man7.org — signal(7)](https://man7.org/linux/man-pages/man7/signal.7.html) — Complete signal reference: default actions, which signals can be caught or ignored, and the `128+N` exit-code convention.
- [Julia Evans — How Linux signals work](https://jvns.ca/blog/2016/10/10/how-linux-signals-work/) — Accessible explanation of signal delivery, blocking, and the difference between SIGTERM and SIGKILL with diagrams.
- [procps-ng source](https://gitlab.com/procps-ng/procps) — Source for `ps`, `top`, `pgrep`, `pstree`, `vmstat`, and `free`; shows exactly which `/proc` fields each metric reads.
- [man7.org — fork(2)](https://man7.org/linux/man-pages/man2/fork.2.html) — The kernel call that creates every process; essential for understanding the parent-child relationships `pstree` visualises.
