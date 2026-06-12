# Exercise: IPC Mechanisms

## Setup

```bash
mkdir -p ~/practice
```

## Task 1: Explore Pipe Buffer Size

```bash
# Check the maximum pipe buffer size
cat /proc/sys/fs/pipe-max-size

# Observe pipes in /proc/self/fd during a pipeline
bash -c 'ls -la /proc/self/fd' | cat
```

## Task 2: Create and Use a Named Pipe (FIFO)

Create a named pipe in your practice directory:

```bash
# Create the named pipe
mkfifo ~/practice/myfifo

# Verify it's a pipe (note the 'p' in permissions)
ls -la ~/practice/myfifo
file ~/practice/myfifo

# Verify with test -p
test -p ~/practice/myfifo && echo "Confirmed: it's a named pipe"
```

Use the named pipe for data transfer between two subshells:

```bash
# Write to the pipe in the background
echo "IPC test message $(date)" > ~/practice/myfifo &

# Read from the pipe (this unblocks the writer)
RECEIVED=$(cat ~/practice/myfifo)
echo "Received: $RECEIVED"
```

## Task 3: Use /dev/shm for Fast Temporary Storage

```bash
# Write data to shared memory
echo "Hello from process $$" > /dev/shm/ipc_test_$$

# Read it back (simulating another process)
cat /dev/shm/ipc_test_$$

# Check it's in RAM (df shows it under tmpfs)
df -h /dev/shm

# Clean up
rm -f /dev/shm/ipc_test_$$
```

## Task 4: Inspect SysV IPC Resources

```bash
# Show all SysV IPC objects (shared mem, queues, semaphores)
ipcs

# Detailed shared memory listing
ipcs -m

# Detailed message queue listing
ipcs -q

# Detailed semaphore listing
ipcs -s
```

On a fresh system, you may see nothing. That's fine — it means no SysV IPC objects exist.

## Task 5: Examine Unix Domain Sockets

```bash
# List Unix domain sockets on the system
ss -xl 2>/dev/null | head -20

# Check for common sockets
ls -la /var/run/*.sock 2>/dev/null || echo "No .sock files in /var/run"
ls -la /run/*.sock 2>/dev/null | head -5
```

## Task 6: Pipeline Exercise

Demonstrate a real pipeline with multiple stages:

```bash
# Count the 10 most common words in /proc/meminfo
cat /proc/meminfo | awk '{print $1}' | sort | uniq -c | sort -rn | head -10
```

## Expected Outcome

- `~/practice/myfifo` exists as a named pipe (FIFO)
- You can use `/dev/shm` for temporary RAM-backed storage
- You understand `ipcs` output and can list IPC resources
