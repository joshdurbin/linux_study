# Exercise: Sockets

## Tasks

1. **Socket inventory**: Run `ss -xlnp` (Unix sockets) and `ss -tlnp` (TCP listeners). Save both to `~/practice/socket_inventory.txt`.

2. **Explore /proc/net**: Read raw socket data from the kernel:
   ```bash
   echo "=== TCP ===" > ~/practice/proc_net_sockets.txt
   cat /proc/net/tcp 2>/dev/null | head -10 >> ~/practice/proc_net_sockets.txt
   echo "=== Unix ===" >> ~/practice/proc_net_sockets.txt
   cat /proc/net/unix 2>/dev/null | head -10 >> ~/practice/proc_net_sockets.txt
   ```

3. **Create a Unix socket server/client** using netcat:
   ```bash
   rm -f /tmp/test.sock
   nc -lU /tmp/test.sock &
   NC_PID=$!
   sleep 0.5
   echo "hello via unix socket" | nc -U /tmp/test.sock
   kill $NC_PID 2>/dev/null
   echo "unix socket test complete" > ~/practice/unix_socket_test.txt
   ls -la /tmp/test.sock 2>/dev/null || echo "/tmp/test.sock removed after close" >> ~/practice/unix_socket_test.txt
   ```

4. **Socket lifecycle with strace**: Observe socket() and connect() syscalls:
   ```bash
   strace -e socket,connect,bind nc -z localhost 22 2>&1 > ~/practice/socket_strace.txt || \
   strace -e socket,connect nc -z localhost 80 2>&1 > ~/practice/socket_strace.txt || \
   echo "strace socket observation" > ~/practice/socket_strace.txt
   ```

5. **Socket options reference**: Write `~/practice/socket_options.txt` listing 5 socket options from the lesson with a one-line description each (SO_REUSEADDR, SO_KEEPALIVE, TCP_NODELAY, SO_SNDBUF, SO_REUSEPORT).

## Hints

- `nc -lU /path` creates a Unix domain socket server; `nc -U /path` connects to one
- `/proc/net/tcp` stores addresses in little-endian hex — `0100007F:0050` = 127.0.0.1:80
- Abstract namespace sockets in `ss -xlnp` appear as `* @...` with no filesystem path
