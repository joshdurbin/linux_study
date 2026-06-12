# Signals

## What Are Signals?

A **signal** is an asynchronous notification sent to a process. When a signal is delivered, the process interrupts its normal execution and handles the signal — unless it's blocked or being ignored.

Signals are the Unix mechanism for:
- Terminating processes (`SIGTERM`, `SIGKILL`)
- Notifying processes of events (`SIGCHLD` when a child exits)
- Handling user interrupts (`SIGINT` from Ctrl-C)
- Reloading configuration (`SIGHUP` traditionally)

## Signal Disposition

Each signal has a **disposition** — what happens when it's received:

| Disposition | Meaning |
|-------------|---------|
| **Default** | The kernel's built-in action (usually terminate or ignore) |
| **Ignore** | `SIG_IGN` — signal is discarded |
| **Handle** | A custom function in the process runs |
| **Block** | Signal is held pending until unblocked (not lost) |

**SIGKILL (9) and SIGSTOP cannot be caught, blocked, or ignored** — they always work.

## Common Signals

| Signal | Number | Default | Typical Use |
|--------|--------|---------|-------------|
| `SIGHUP` | 1 | Terminate | Hangup / reload config (daemons) |
| `SIGINT` | 2 | Terminate | Ctrl-C keyboard interrupt |
| `SIGQUIT` | 3 | Core dump | Ctrl-\ keyboard quit |
| `SIGKILL` | 9 | Terminate | Force kill — uncatchable |
| `SIGTERM` | 15 | Terminate | Graceful termination request |
| `SIGPIPE` | 13 | Terminate | Write to broken pipe |
| `SIGUSR1` | 10 | Terminate | User-defined purpose |
| `SIGUSR2` | 12 | Terminate | User-defined purpose |
| `SIGCHLD` | 17 | Ignore | Child process stopped or exited |
| `SIGSTOP` | 19 | Stop | Pause process — uncatchable |
| `SIGCONT` | 18 | Continue | Resume stopped process |
| `SIGWINCH` | 28 | Ignore | Terminal window resize |

## Sending Signals: kill, pkill, killall

Despite the name, `kill` sends any signal (not just SIGKILL):

```bash
# Send SIGTERM (default) to PID 1234
kill 1234

# Send SIGKILL
kill -9 1234
kill -SIGKILL 1234
kill -KILL 1234      # all three are equivalent

# Send SIGHUP to reload config
kill -HUP 1234
kill -1 1234

# Send SIGUSR1
kill -USR1 1234

# Send to all processes with this name
pkill -TERM nginx
killall -HUP nginx

# Send to processes matching a pattern
pkill -f "python app.py"
```

List all signal names and numbers:
```bash
kill -l
```

## Observing Signals: What Happens on Delivery

```bash
# Start a background process
sleep 300 &
PID=$!
echo "Started sleep, PID=$PID"

# Send SIGTERM (graceful)
kill $PID
wait $PID
echo "Exit status: $?"    # 143 = 128+15 (terminated by signal 15)

# Start another and force kill
sleep 300 &
PID=$!
kill -9 $PID
wait $PID
echo "Exit status: $?"    # 137 = 128+9 (killed by signal 9)
```

Exit status convention: `128 + signal_number` when a process is killed by a signal.

## trap in Shell Scripts

`trap` lets a shell script respond to signals. This is essential for cleanup on interruption.

```bash
#!/bin/bash

# Define cleanup function
cleanup() {
    echo "Caught signal, cleaning up..."
    rm -f /tmp/mylock
    exit 0
}

# Register the trap
trap cleanup SIGTERM SIGINT SIGHUP

# Create a lock file
touch /tmp/mylock

echo "Running... PID=$$"
while true; do
    echo "Working at $(date)"
    sleep 5
done
```

### Common trap Patterns

```bash
# Cleanup temp files on exit (EXIT runs on any exit, not just signals)
trap 'rm -f /tmp/tmpfile.$$' EXIT

# Ignore SIGPIPE (common in pipelines)
trap '' PIPE

# Re-run on SIGHUP (daemon-style reload)
trap 'echo "Reloading config..."; load_config' HUP

# Print a message and exit cleanly
trap 'echo "Interrupted"; exit 1' INT TERM
```

### Resetting a Trap

```bash
# Reset to default behavior
trap - SIGTERM

# Ignore a signal
trap '' SIGTERM
```

## Signals and Processes: Practical Scenarios

```bash
# Graceful nginx reload (no dropped connections)
sudo kill -HUP $(cat /var/run/nginx.pid)

# Force a core dump for debugging
kill -ABRT <PID>

# Resume a stopped process
kill -CONT <PID>

# Check pending signals for a process
cat /proc/<PID>/status | grep Sig
# SigPnd: pending signals (bitmask)
# SigBlk: blocked signals
# SigIgn: ignored signals
# SigCgt: caught (handled) signals
```

## Further Reading

- [signal(7) — man7.org](https://man7.org/linux/man-pages/man7/signal.7.html) — comprehensive reference for every standard Linux signal: default disposition, whether it can be caught/blocked/ignored, async-signal-safe functions, and signal delivery in multi-threaded processes.
- [sigaction(2) — man7.org](https://man7.org/linux/man-pages/man2/sigaction.2.html) — documents the full `struct sigaction` interface: `sa_handler`, `sa_sigaction` (for `SI_*` info), `sa_mask`, and flags like `SA_RESTART`, `SA_NODEFER`, and `SA_SIGINFO`.
- [Julia Evans — Should you be scared of signals?](https://jvns.ca/blog/2016/06/13/should-you-be-scared-of-signals/) — practical explanation of async-signal safety, why signals in multi-threaded programs are tricky, and when `signalfd(2)` is a better approach than traditional signal handlers.
- [linux-insides — Signals](https://0xax.gitbooks.io/linux-insides/content/) — covers the kernel-side signal delivery path: how signals enter the pending bitmask, when they are checked (syscall return, scheduler), and how `sigreturn` restores the interrupted context.
- [kill(2) — man7.org](https://man7.org/linux/man-pages/man2/kill.2.html) — documents the `kill(2)` syscall, `tgkill(2)` for thread-specific delivery, and the `kill -0` trick used to check process existence without sending a real signal.
