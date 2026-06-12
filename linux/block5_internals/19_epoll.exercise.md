# Exercise: epoll and Event-Driven I/O

## Setup

```bash
mkdir -p ~/practice/epoll
```

## Task 1: Observe epoll in Running Servers

```bash
# Find a process that uses epoll (nginx, redis, postgres, sshd, etc.)
TARGET_PID=""
for name in nginx redis-server postgres sshd; do
    PID=$(pgrep "$name" 2>/dev/null | head -1)
    if [ -n "$PID" ]; then
        TARGET_PID=$PID
        TARGET_NAME=$name
        break
    fi
done

if [ -n "$TARGET_PID" ]; then
    echo "Found: $TARGET_NAME (PID $TARGET_PID)"
    echo ""
    echo "FDs open:"
    ls /proc/$TARGET_PID/fd 2>/dev/null | wc -l
    echo ""
    echo "epoll instances:"
    ls -la /proc/$TARGET_PID/fd 2>/dev/null | grep eventpoll
else
    echo "No common event-driven servers found — checking current shell"
    ls -la /proc/$$/fd | head -10
fi
```

## Task 2: Identify epoll FDs via fdinfo

```bash
TARGET_PID=$(pgrep sshd | head -1)
[ -z "$TARGET_PID" ] && TARGET_PID=$$

echo "FD info for PID $TARGET_PID:"
for fd_link in /proc/$TARGET_PID/fd/*; do
    target=$(readlink "$fd_link" 2>/dev/null)
    if echo "$target" | grep -q "eventpoll"; then
        fd_num=$(basename "$fd_link")
        echo "  FD $fd_num → $target"
        echo "  fdinfo:"
        cat /proc/$TARGET_PID/fdinfo/$fd_num 2>/dev/null | head -10
    fi
done
```

## Task 3: Trace epoll Syscalls with strace

```bash
# Trace epoll calls for a command that uses networking
echo "Tracing epoll syscalls for curl:"
strace -e trace=epoll_create1,epoll_ctl,epoll_wait \
    curl -s https://example.com -o /dev/null 2>&1 | grep -E "epoll|Error" | head -20
```

## Task 4: Observe O_NONBLOCK Flag

```bash
# Create a socket and check its flags
python3 -c "
import socket, fcntl, os

# Blocking socket (default)
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
flags = fcntl.fcntl(s.fileno(), fcntl.F_GETFL)
print(f'Blocking socket flags: {oct(flags)}')
print(f'O_NONBLOCK set: {bool(flags & os.O_NONBLOCK)}')

# Set non-blocking
fcntl.fcntl(s.fileno(), fcntl.F_SETFL, flags | os.O_NONBLOCK)
flags_after = fcntl.fcntl(s.fileno(), fcntl.F_GETFL)
print(f'Non-blocking socket flags: {oct(flags_after)}')
print(f'O_NONBLOCK set: {bool(flags_after & os.O_NONBLOCK)}')
s.close()
" 2>/dev/null || echo "Python3 not available — using C perspective in lesson"

# Check O_NONBLOCK on an actual process FD
PID=$(pgrep sshd | head -1)
if [ -n "$PID" ]; then
    echo ""
    echo "fdinfo flags for sshd FDs:"
    for fd in /proc/$PID/fd/[0-9]; do
        flags=$(awk '/^flags:/{print $2}' /proc/$PID/fdinfo/$(basename $fd) 2>/dev/null)
        [ -z "$flags" ] && continue
        # O_NONBLOCK is 0o4000 = 2048 decimal = 0x800
        nonblock=$(( (16#${flags##0x} & 2048) != 0 ))
        [ "$nonblock" = "1" ] && echo "  FD $(basename $fd): O_NONBLOCK set (flags=$flags)"
    done
fi
```

## Task 5: Write a Simple Epoll Observer Script

```bash
cat > ~/practice/epoll/epoll_observer.sh << 'EOF'
#!/bin/bash
# Find processes using epoll and report their FD stats
echo "=== Epoll Users ==="
for pid_fd_dir in /proc/[0-9]*/fd; do
    pid=$(echo "$pid_fd_dir" | cut -d/ -f3)
    comm=$(cat /proc/$pid/comm 2>/dev/null || continue)

    # Check for eventpoll FDs
    epoll_count=$(ls -la "$pid_fd_dir" 2>/dev/null | grep -c "eventpoll" || echo 0)
    [ "$epoll_count" -eq 0 ] && continue

    total_fds=$(ls "$pid_fd_dir" 2>/dev/null | wc -l)
    echo "PID $pid ($comm): $epoll_count epoll instance(s), $total_fds total FDs"
done | head -20
EOF
chmod +x ~/practice/epoll/epoll_observer.sh
bash ~/practice/epoll/epoll_observer.sh
```

## Task 6: Select vs Epoll Performance Concept

```bash
cat > ~/practice/epoll/scaling_demo.sh << 'EOF'
#!/bin/bash
# Demonstrate why epoll scales: it only returns ready FDs
# Simulate the O(n) vs O(1) difference conceptually

N=10000
READY=5

echo "At $N connections with $READY ready:"
echo ""
echo "select()/poll() approach:"
echo "  Must check $N FDs on every wait call"
echo "  Even with $READY ready, still scans all $N"
echo "  Cost: O($N) = O(n) per call"
echo ""
echo "epoll approach:"
echo "  Returns only the $READY ready FDs"
echo "  Kernel maintains registered set internally"
echo "  Cost: O($READY) = O(ready) — independent of total FD count"
echo ""
echo "At 1M connections with 100 active:"
echo "  select: 1,000,000 FD checks"
echo "  epoll: 100 FD checks"
EOF
chmod +x ~/practice/epoll/scaling_demo.sh
bash ~/practice/epoll/scaling_demo.sh
```

## Task 7: Connect Level vs Edge Triggered Behavior to Real Tools

```bash
echo "=== Level vs Edge Triggered in Real Systems ==="
echo ""
echo "Level-triggered (default EPOLLIN):"
echo "  nginx default: uses LT for most connections"
echo "  Safe: if partial read leaves data, next epoll_wait fires again"
echo ""
echo "Edge-triggered (EPOLLIN | EPOLLET):"
echo "  Redis uses ET: must drain FD fully on each notification"
echo "  Requires O_NONBLOCK + loop until EAGAIN"
echo "  More efficient: fewer epoll_wait calls per request"
echo ""
echo "Check /proc/PID/fdinfo for event flags:"
PID=$(pgrep redis-server 2>/dev/null | head -1)
if [ -n "$PID" ]; then
    echo "Redis fdinfo sample:"
    cat /proc/$PID/fdinfo/$(ls /proc/$PID/fd | head -3 | tail -1) 2>/dev/null | head -5
fi
```

## Expected Outcome

- Running event-driven servers (nginx, redis, sshd) show `anon_inode:[eventpoll]` FDs
- `/proc/<pid>/fdinfo/<epoll_fd>` shows registered `tfd` entries
- `strace -e epoll_*` on curl shows `epoll_create1` and `epoll_wait` calls
- O_NONBLOCK flag is visible in fdinfo flags field
- `~/practice/epoll/epoll_observer.sh` finds processes using epoll and reports their FD counts
