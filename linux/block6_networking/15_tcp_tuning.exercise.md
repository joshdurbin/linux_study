# Exercise: TCP Tuning

## Setup

```bash
mkdir -p ~/practice/tcp_tuning
```

## Task 1: Survey Current TCP Parameters

```bash
echo "=== Buffer Sizes ==="
sysctl net.core.rmem_default net.core.rmem_max
sysctl net.core.wmem_default net.core.wmem_max
sysctl net.ipv4.tcp_rmem net.ipv4.tcp_wmem

echo ""
echo "=== Congestion Control ==="
sysctl net.ipv4.tcp_congestion_control
sysctl net.ipv4.tcp_available_congestion_control

echo ""
echo "=== Keepalive ==="
sysctl net.ipv4.tcp_keepalive_time
sysctl net.ipv4.tcp_keepalive_intvl
sysctl net.ipv4.tcp_keepalive_probes

echo ""
echo "=== TIME_WAIT and Ports ==="
sysctl net.ipv4.tcp_tw_reuse
sysctl net.ipv4.ip_local_port_range

echo ""
echo "=== Listen Backlog ==="
sysctl net.core.somaxconn
sysctl net.ipv4.tcp_max_syn_backlog
```

## Task 2: Count TIME_WAIT Sockets

```bash
# Count TIME_WAIT sockets (ss from block6/05)
echo "TIME_WAIT socket count:"
ss -ant | awk '$1 == "TIME-WAIT" {count++} END {print count+0}'

# Or using the state filter
ss -ant state time-wait | wc -l

# Look at the distribution of socket states
echo "Socket state distribution:"
ss -ant | awk 'NR>1 {states[$1]++} END {for (s in states) print states[s], s}' | sort -rn
```

## Task 3: Tune Keepalive Settings

```bash
# Read current values
echo "Current keepalive settings:"
echo "  time: $(sysctl -n net.ipv4.tcp_keepalive_time)s"
echo "  intvl: $(sysctl -n net.ipv4.tcp_keepalive_intvl)s"
echo "  probes: $(sysctl -n net.ipv4.tcp_keepalive_probes)"

# Tune for faster dead connection detection
sudo sysctl -w net.ipv4.tcp_keepalive_time=60
sudo sysctl -w net.ipv4.tcp_keepalive_intvl=10
sudo sysctl -w net.ipv4.tcp_keepalive_probes=6

echo ""
echo "Tuned keepalive settings:"
sysctl net.ipv4.tcp_keepalive_time net.ipv4.tcp_keepalive_intvl net.ipv4.tcp_keepalive_probes

# Maximum time to detect dead connection: time + (probes * intvl)
TIME=$(sysctl -n net.ipv4.tcp_keepalive_time)
INTVL=$(sysctl -n net.ipv4.tcp_keepalive_intvl)
PROBES=$(sysctl -n net.ipv4.tcp_keepalive_probes)
echo "Max detection time: $((TIME + PROBES * INTVL)) seconds"
```

## Task 4: Enable BBR Congestion Control

```bash
# Check if BBR is available
sysctl net.ipv4.tcp_available_congestion_control | grep -q bbr && echo "BBR available" || echo "BBR not loaded"

# Try to load BBR
sudo modprobe tcp_bbr 2>/dev/null && echo "BBR module loaded" || echo "BBR module unavailable"

# Switch to BBR if available
if sysctl net.ipv4.tcp_available_congestion_control 2>/dev/null | grep -q bbr; then
    sudo sysctl -w net.ipv4.tcp_congestion_control=bbr
    echo "Switched to BBR: $(sysctl -n net.ipv4.tcp_congestion_control)"
else
    echo "BBR not available — current algorithm: $(sysctl -n net.ipv4.tcp_congestion_control)"
fi
```

## Task 5: Inspect a Live Connection's TCP Info

```bash
# Start a background connection to something
curl -s https://example.com > /dev/null &
CURL_PID=$!
sleep 1

# Show detailed TCP info for active connections (ss -ti)
echo "TCP socket info for active connections:"
ss -ti dst example.com 2>/dev/null | head -20

wait $CURL_PID 2>/dev/null

# Show general socket stats
ss -s
```

## Task 6: Write a Tuning Summary Script

```bash
cat > ~/practice/tcp_tuning/tcp_summary.sh << 'EOF'
#!/bin/bash
echo "=== TCP Tuning Summary ==="

echo "Congestion control: $(sysctl -n net.ipv4.tcp_congestion_control)"
echo "Available algorithms: $(sysctl -n net.ipv4.tcp_available_congestion_control)"
echo ""

echo "Buffer max (recv/send):"
echo "  rmem_max: $(sysctl -n net.core.rmem_max)"
echo "  wmem_max: $(sysctl -n net.core.wmem_max)"
echo ""

echo "Keepalive:"
echo "  time: $(sysctl -n net.ipv4.tcp_keepalive_time)s"
echo "  intvl: $(sysctl -n net.ipv4.tcp_keepalive_intvl)s"
echo "  probes: $(sysctl -n net.ipv4.tcp_keepalive_probes)"
echo ""

echo "TIME_WAIT reuse: $(sysctl -n net.ipv4.tcp_tw_reuse)"
echo "Ephemeral ports: $(sysctl -n net.ipv4.ip_local_port_range)"
echo "Listen backlog: $(sysctl -n net.core.somaxconn)"
echo "TIME_WAIT count: $(ss -ant state time-wait 2>/dev/null | wc -l)"
EOF
chmod +x ~/practice/tcp_tuning/tcp_summary.sh
bash ~/practice/tcp_tuning/tcp_summary.sh
```

## Expected Outcome

- All TCP sysctl parameters are readable
- `ss` shows socket state distribution and TIME_WAIT count
- Keepalive parameters were tuned and verified
- `~/practice/tcp_tuning/tcp_summary.sh` reports current TCP tuning state
