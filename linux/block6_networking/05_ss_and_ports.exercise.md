# Exercise: ss and Port Inspection

## Setup

```bash
mkdir -p ~/practice
```

## Task 1: List All Listening TCP Ports

```bash
ss -tlnp
```

Note which ports are listening and which processes own them. Common ones:
- Port 22: sshd (SSH)
- Port 80/443: web server
- Port 5432: PostgreSQL
- Port 3306: MySQL

## Task 2: List All Socket Types

```bash
# TCP listening
echo "=== TCP Listening ==="
ss -tlnp

# UDP sockets
echo "=== UDP ==="
ss -ulnp

# Unix domain sockets (listening only)
echo "=== Unix sockets ==="
ss -xlnp | head -10
```

## Task 3: Save Port Information

```bash
echo "=== Open Ports on $(hostname) at $(date) ===" > ~/practice/ports.txt
echo "" >> ~/practice/ports.txt
echo "--- TCP Listening ---" >> ~/practice/ports.txt
ss -tlnp >> ~/practice/ports.txt
echo "" >> ~/practice/ports.txt
echo "--- UDP Listening ---" >> ~/practice/ports.txt
ss -ulnp >> ~/practice/ports.txt

cat ~/practice/ports.txt
```

## Task 4: Start a Test Service and Find It

Start a temporary listener on a high port to practice finding it:

```bash
# Start a test TCP listener in background
nc -l -p 19876 &
NC_PID=$!
sleep 0.5

# Find it with ss
echo "Looking for port 19876:"
ss -tlnp | grep 19876

# Also try
ss -tlnp | grep ":19876"

# Kill the listener
kill $NC_PID 2>/dev/null || true
wait $NC_PID 2>/dev/null || true
```

## Task 5: Check Socket States

```bash
# Start a connection in background
(sleep 5 | nc 127.0.0.1 19877 2>/dev/null) &
NC_CLIENT=$!

# Start a server in another background
nc -l -p 19877 &
NC_SERVER=$!
sleep 1

# Check the ESTABLISHED connection
echo "Established connections:"
ss -tnp state established

# Check all states
echo "All TCP sockets:"
ss -tn

# Cleanup
kill $NC_CLIENT $NC_SERVER 2>/dev/null || true
wait 2>/dev/null || true
```

## Task 6: Compare ss with netstat (if available)

```bash
# Modern way
ss -tlnp

# Legacy way (may not be installed)
netstat -tulpn 2>/dev/null | head -15 || echo "netstat not installed"
```

## Task 7: Get Socket Statistics Summary

```bash
ss -s
```

This shows:
- Total sockets
- TCP in each state
- UDP count

Append to ports.txt:
```bash
echo "" >> ~/practice/ports.txt
echo "--- Socket Summary ---" >> ~/practice/ports.txt
ss -s >> ~/practice/ports.txt
```

## Expected Outcome

- `~/practice/ports.txt` contains "LISTEN" (from ss -tlnp output)
- You can identify which process owns a given port
- You understand common TCP socket states
