# Job Control

You've seen the basics: `&` to background a job, `jobs`/`bg`/`fg` to manage it, and `nohup` to survive logout. This lesson goes deeper into job lifecycle, job specs, `wait`, `disown`, and exit-code handling for background work.

## How Job Control Works

The shell tracks each backgrounded or suspended process as a **job** with a job number. The kernel uses process groups and the terminal's foreground process group to implement stop/continue signals automatically when you press Ctrl-Z or Ctrl-C.

```
Terminal
  └── shell (session leader)
        ├── job [1]: sleep 100   ← background process group
        └── job [2]: vim         ← foreground process group  ← Ctrl-C targets this
```

## Job Specifications

```bash
%1        # job number 1
%2        # job number 2
%%        # current job (same as %+)
%+        # current job (most recently foregrounded/backgrounded)
%-        # previous job
%sleep    # job whose command starts with "sleep"
```

```bash
sleep 100 &    # [1] 4321
sleep 200 &    # [2] 4322
vim &          # [3] 4323 (Ctrl-Z also suspends to background)

jobs           # list all jobs with number, state, command
kill %2        # kill job 2 (sleep 200)
fg %3          # bring vim to foreground
bg %1          # resume job 1 in background if suspended
```

## $! — PID of the Last Background Job

```bash
sleep 100 &
BG_PID=$!           # capture PID immediately after &
echo "Started PID $BG_PID"
ps -p $BG_PID       # confirm it's running
```

Always capture `$!` right after `&` — it's overwritten by the next backgrounded command.

## wait — Synchronize with Background Jobs

`wait` blocks until a background job completes and returns its exit code.

```bash
# Wait for a specific PID
sleep 2 &
pid=$!
wait $pid
echo "sleep exited: $?"

# Wait for a job spec
sleep 3 &
wait %1
echo "job 1 done: $?"

# Wait for ALL background jobs
sleep 1 &
sleep 2 &
wait        # blocks until all complete
echo "all done"

# Collect exit codes from multiple jobs
job1_exit() { false; }
job2_exit() { true;  }
job1_exit & p1=$!
job2_exit & p2=$!
wait $p1; echo "job1 exit: $?"
wait $p2; echo "job2 exit: $?"
```

`wait` without arguments waits for all current children. The shell emits a completion notice (e.g., `[1]+ Done sleep 2`) when you next hit Enter or when `wait` returns.

## disown — Detach a Job from the Shell

`nohup` prevents SIGHUP before the process starts. `disown` removes an already-running job from the shell's job table, so it won't receive SIGHUP when the shell exits.

```bash
sleep 1000 &
jobs          # [1]+ Running   sleep 1000

disown %1     # remove from job table
jobs          # (empty) — shell no longer tracks it

# Shorthand: start, background, and immediately disown
sleep 1000 & disown
```

After `disown`, you can no longer use `fg`/`bg`/`jobs` to manage the process, but it continues running. Find it later with `ps` using the PID you captured in `$!`.

### disown vs nohup

| | `nohup` | `disown` |
|--|---------|---------|
| When | Before starting | After job is already running |
| Output | Redirects to `nohup.out` | No change to output |
| Effect | Sets SIGHUP to SIG_IGN | Removes from shell's job list |

## Ctrl-Z — Suspend to Background

Pressing Ctrl-Z sends SIGSTOP to the foreground process group, suspending it:

```bash
sleep 100       # running in foreground
# Press Ctrl-Z
# [1]+  Stopped   sleep 100

jobs            # shows state: Stopped
bg %1           # resume in background (sends SIGCONT)
fg %1           # bring back to foreground
```

A suspended process is not running — it consumes no CPU. It holds its open files, memory, and terminal state.

## Pipelines as Jobs

A pipeline is a single job — all commands in the pipeline belong to the same process group:

```bash
find / -name "*.log" 2>/dev/null | wc -l &
# [1] 5678   ← PID is the last command in the pipeline (wc -l)

jobs          # [1]+ Running   find / -name "*.log" 2>/dev/null | wc -l
```

`$!` gives the PID of the last command in the pipeline. `kill %1` sends the signal to the entire process group, stopping all commands in the pipeline.

## Practical Patterns

```bash
# Run a slow command, do other work, then collect the result
long_command > /tmp/result.txt &
LONG_PID=$!
echo "doing other work..."
wait $LONG_PID
echo "long_command exited: $?; result:"
cat /tmp/result.txt

# Run N jobs in parallel, fail fast if any fails
pids=()
for i in 1 2 3; do
    sleep $i &
    pids+=($!)
done
failed=0
for pid in "${pids[@]}"; do
    wait "$pid" || failed=1
done
[ $failed -eq 0 ] && echo "all OK" || echo "at least one failed"

# Keep a background job alive even after logout
nohup ./server.sh > /tmp/server.log 2>&1 &
echo "Server PID: $!"
```

## Further Reading

- [GNU Bash Manual — Job Control](https://www.gnu.org/software/bash/manual/bash.html#Job-Control) — Authoritative reference for job specs (`%1`, `%%`, `%+`), `jobs`/`fg`/`bg`/`disown`, and how bash interacts with the kernel's process group API.
- [man7.org — wait(2)](https://man7.org/linux/man-pages/man2/wait.2.html) — The kernel syscall underlying the shell's `wait` builtin; documents how exit status, signal termination codes, and `WIFEXITED`/`WIFSIGNALED` macros work.
- [POSIX — wait utility](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/wait.html) — The POSIX specification for the `wait` shell builtin, including exit status semantics for both specific PIDs and all-children waits.
- [man7.org — setpgid(2)](https://man7.org/linux/man-pages/man2/setpgid.2.html) — Explains process groups and sessions; shows how the shell uses `setpgid` to create a new process group for each pipeline (job).
- [man7.org — termios(3)](https://man7.org/linux/man-pages/man3/termios.3.html) — Documents the terminal control settings including `TOSTOP`, which makes background processes stop when writing to the terminal.
