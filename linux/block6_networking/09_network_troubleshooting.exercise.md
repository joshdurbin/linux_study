# Exercise: Network Troubleshooting

## Setup

```bash
mkdir -p ~/practice
sudo apt-get install -y netcat-openbsd traceroute mtr-tiny 2>/dev/null || true
```

## Task 1: Layer 2-3 Check: Interfaces and Routing

```bash
echo "=== Interface Check ==="
ip link show
echo ""
echo "=== IP Addresses ==="
ip addr show
echo ""
echo "=== Routing Table ==="
ip route show
```

Are all expected interfaces UP with LOWER_UP? Is there a default route?

## Task 2: Ping Tests

```bash
# Test loopback (should always work)
echo "=== Loopback ping ==="
ping -c 3 127.0.0.1

# Test default gateway (if one exists)
GW=$(ip route show default 2>/dev/null | awk '/default/ {print $3; exit}')
if [ -n "$GW" ]; then
    echo "=== Gateway ping ($GW) ==="
    ping -c 3 $GW
else
    echo "No default gateway configured"
fi
```

## Task 3: Test Port Reachability with nc

```bash
# Test loopback connectivity on a port
# Start a listener
nc -l -p 12345 &
NC_PID=$!
sleep 0.5

# Test the port
echo "Testing port 12345 on localhost:"
nc -zv 127.0.0.1 12345 2>&1

# Clean up
kill $NC_PID 2>/dev/null || true
wait $NC_PID 2>/dev/null || true

# Test a closed port (should fail)
echo "Testing closed port 12346 (should fail):"
nc -zv -w 2 127.0.0.1 12346 2>&1 || echo "Port 12346 is closed (expected)"
```

## Task 4: Check DNS

```bash
echo "=== DNS Configuration ==="
cat /etc/resolv.conf

echo ""
echo "=== DNS Resolution Test ==="
dig +short localhost 2>/dev/null || host localhost 2>/dev/null
```

## Task 5: Write a Connectivity Check Script

Create a reusable network check script:

```bash
cat > ~/practice/network_check.sh << 'SCRIPT'
#!/bin/bash
# network_check.sh — layer-by-layer connectivity validation
# Usage: ./network_check.sh [target-ip] [hostname] [port]

PASS_COUNT=0
FAIL_COUNT=0

result() {
    local label=$1
    local status=$2
    local detail=${3:-""}
    if [ "$status" = "ok" ]; then
        echo "  OK    $label $detail"
        ((PASS_COUNT++))
    else
        echo "  FAIL  $label $detail"
        ((FAIL_COUNT++))
    fi
}

echo "================================="
echo "Network Connectivity Check"
echo "$(date)"
echo "================================="

# Layer 2: Interface check
echo ""
echo "[ Layer 2: Interfaces ]"
UP_IFACES=$(ip link show up | grep -v lo | grep -c UP || true)
if [ "$UP_IFACES" -gt 0 ]; then
    result "Network interfaces up" ok "($UP_IFACES non-loopback)"
else
    result "Network interfaces up" fail "(none UP besides lo)"
fi

# Layer 3: IP address check
echo ""
echo "[ Layer 3: IP Addresses ]"
HAS_IP=$(ip -4 addr show | grep -v '127\.' | grep -c 'inet' || true)
if [ "$HAS_IP" -gt 0 ]; then
    MY_IP=$(ip -4 addr | grep -v '127\.' | grep -oP '(?<=inet )\d+\.\d+\.\d+\.\d+' | head -1)
    result "Has IP address" ok "($MY_IP)"
else
    result "Has IP address" fail
fi

# Layer 3: Default route
echo ""
echo "[ Layer 3: Routing ]"
DEFAULT_GW=$(ip route show default 2>/dev/null | awk '/default/ {print $3; exit}')
if [ -n "$DEFAULT_GW" ]; then
    result "Default route exists" ok "(via $DEFAULT_GW)"
else
    result "Default route exists" fail
fi

# Layer 3: Loopback ping
echo ""
echo "[ Layer 3: Ping Tests ]"
if ping -c 1 -W 2 127.0.0.1 > /dev/null 2>&1; then
    result "Loopback (127.0.0.1)" ok
else
    result "Loopback (127.0.0.1)" fail
fi

# Gateway ping
if [ -n "$DEFAULT_GW" ]; then
    if ping -c 1 -W 3 "$DEFAULT_GW" > /dev/null 2>&1; then
        result "Default gateway ($DEFAULT_GW)" ok
    else
        result "Default gateway ($DEFAULT_GW)" fail
    fi
fi

# Layer 7: DNS check
echo ""
echo "[ Layer 7: DNS ]"
NS=$(grep '^nameserver' /etc/resolv.conf 2>/dev/null | head -1 | awk '{print $2}')
if [ -n "$NS" ]; then
    result "Nameserver configured" ok "($NS)"
else
    result "Nameserver configured" fail
fi

# Resolve localhost
if dig +short localhost > /dev/null 2>&1; then
    result "DNS resolution (localhost)" ok
else
    result "DNS resolution (localhost)" fail
fi

echo ""
echo "================================="
echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"
echo "================================="
[ "$FAIL_COUNT" -eq 0 ]
SCRIPT

chmod +x ~/practice/network_check.sh
echo "Script created. Running it:"
~/practice/network_check.sh
```

## Task 6: Traceroute (if available)

```bash
# Trace to loopback
traceroute -n 127.0.0.1 2>/dev/null || echo "traceroute not available"

# If internet: trace to a public IP
traceroute -n -m 5 8.8.8.8 2>/dev/null | head -10 || true
```

## Expected Outcome

- `~/practice/network_check.sh` exists and is executable
- The script tests ping reachability, port connectivity, and DNS resolution
- You can diagnose connectivity issues layer by layer
