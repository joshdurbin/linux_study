# Exercise: conntrack

## Setup

```bash
mkdir -p ~/practice/conntrack
sudo apt-get install -y conntrack 2>/dev/null || true
```

## Task 1: Check conntrack Table Capacity

```bash
echo "=== conntrack Capacity ==="
echo "Max entries: $(sysctl -n net.netfilter.nf_conntrack_max 2>/dev/null || echo 'module not loaded')"
echo "Current count: $(sysctl -n net.netfilter.nf_conntrack_count 2>/dev/null || echo 'module not loaded')"

# Alternatively from /proc
cat /proc/sys/net/netfilter/nf_conntrack_max 2>/dev/null || echo "conntrack not loaded"
cat /proc/sys/net/netfilter/nf_conntrack_count 2>/dev/null || echo "0"
```

## Task 2: Generate Connections and Watch the Table

```bash
# Generate some connections
curl -s https://google.com -o /dev/null &
curl -s https://example.com -o /dev/null &
curl -s https://cloudflare.com -o /dev/null &
wait

# View the conntrack table
sudo conntrack -L 2>/dev/null | head -20 || \
    sudo cat /proc/net/nf_conntrack 2>/dev/null | head -10 || \
    echo "Note: conntrack may not be available inside this container"

echo ""
echo "Total tracked connections: $(sudo conntrack -C 2>/dev/null || wc -l < /proc/net/nf_conntrack 2>/dev/null || echo 'unavailable')"
```

## Task 3: Filter conntrack Output

```bash
# Show only TCP connections
sudo conntrack -L -p tcp 2>/dev/null | head -10

# Show only ESTABLISHED state
sudo conntrack -L --state ESTABLISHED 2>/dev/null | head -10

# Count by state using awk (awk from block2/02)
echo ""
echo "Connections by state:"
sudo conntrack -L 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i ~ /^(NEW|ESTABLISHED|TIME_WAIT|CLOSE_WAIT)$/) states[$i]++} END {for (s in states) print states[s], s}' | sort -rn
```

## Task 4: Read conntrack Parameters

```bash
echo "=== conntrack Timeout Parameters ==="
for param in \
    net.netfilter.nf_conntrack_tcp_timeout_established \
    net.netfilter.nf_conntrack_tcp_timeout_time_wait \
    net.netfilter.nf_conntrack_udp_timeout \
    net.netfilter.nf_conntrack_udp_timeout_stream; do
    val=$(sysctl -n $param 2>/dev/null)
    if [ -n "$val" ]; then
        echo "$param = ${val}s"
    fi
done
```

## Task 5: Watch conntrack Events in Real Time

```bash
# Start watching events in background
sudo conntrack -E 2>/dev/null &
WATCH_PID=$!
sleep 1

# Generate traffic to create events
curl -s https://httpbin.org/get -o /dev/null 2>/dev/null || \
    curl -s https://example.com -o /dev/null

sleep 2
kill $WATCH_PID 2>/dev/null
echo "Watch events above (NEW/ESTABLISH/DESTROY)"
```

## Task 6: Read from /proc/net/nf_conntrack Directly

```bash
# Parse the raw conntrack table without the conntrack tool
sudo cat /proc/net/nf_conntrack 2>/dev/null | head -10

# Count TCP ESTABLISHED entries using awk
sudo awk '$4 == "ESTABLISHED" {count++} END {print count+0, "ESTABLISHED TCP connections"}' \
    /proc/net/nf_conntrack 2>/dev/null || echo "Table may be empty or unavailable"
```

## Task 7: Write a conntrack Health Check

```bash
cat > ~/practice/conntrack/ct_health.sh << 'EOF'
#!/bin/bash
echo "=== conntrack Health Check ==="

# Check if conntrack is loaded
if ! sysctl net.netfilter.nf_conntrack_count > /dev/null 2>&1; then
    echo "conntrack module not loaded"
    exit 0
fi

MAX=$(sysctl -n net.netfilter.nf_conntrack_max)
COUNT=$(sysctl -n net.netfilter.nf_conntrack_count)
PCT=$((COUNT * 100 / MAX))

echo "Entries: $COUNT / $MAX ($PCT% used)"

if [ $PCT -gt 80 ]; then
    echo "WARNING: conntrack table is above 80% full"
elif [ $PCT -gt 90 ]; then
    echo "CRITICAL: conntrack table almost full — new connections may be dropped"
else
    echo "Status: OK"
fi

echo ""
echo "TCP established timeout: $(sysctl -n net.netfilter.nf_conntrack_tcp_timeout_established 2>/dev/null)s"
echo "UDP timeout:             $(sysctl -n net.netfilter.nf_conntrack_udp_timeout 2>/dev/null)s"
EOF
chmod +x ~/practice/conntrack/ct_health.sh
bash ~/practice/conntrack/ct_health.sh
```

## Expected Outcome

- `sysctl net.netfilter.nf_conntrack_max` shows the table limit
- `conntrack -L` or `/proc/net/nf_conntrack` lists tracked connections
- `conntrack -C` counts the current number of entries
- `conntrack -E` shows real-time events
- `~/practice/conntrack/ct_health.sh` reports utilization as a percentage
