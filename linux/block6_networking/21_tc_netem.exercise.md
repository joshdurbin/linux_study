# Exercise: Traffic Control (tc) and netem

Work through these tasks inside your Linux study container. `tc` requires root privileges. All exercises use the loopback interface (`lo`) to avoid affecting real network traffic.

---

## Setup

```bash
mkdir -p ~/practice/tc
cd ~/practice/tc

# Verify tc is available
tc -V
which tc
```

---

## Task 1 — Show Current Qdiscs on All Interfaces

Explore the default qdisc configuration before making any changes.

```bash
# Show qdiscs on all interfaces
tc qdisc show

# Show qdiscs on loopback specifically
tc qdisc show dev lo

# Show qdiscs on eth0 (or whatever your main interface is)
ip link show | grep -E '^[0-9]+:' | awk -F': ' '{print $2}' | awk '{print $1}' | \
  while read iface; do
    echo "=== $iface ==="
    tc qdisc show dev "$iface"
  done

# Show with statistics
tc -s qdisc show
```

Note the default qdisc type (likely `noqueue` on loopback, `pfifo_fast` or `fq_codel` on eth0).

Save the baseline:

```bash
tc qdisc show > ~/practice/tc/baseline_qdiscs.txt
cat ~/practice/tc/baseline_qdiscs.txt
```

---

## Task 2 — Add netem Delay to Loopback

```bash
# First, test baseline ping RTT to loopback
echo "=== Baseline RTT ==="
ping -c 5 127.0.0.1

# Add 100ms delay to loopback
tc qdisc add dev lo root netem delay 100ms

# Verify the qdisc was added
tc qdisc show dev lo

# Test ping again — RTT should be ~200ms (100ms each direction)
echo "=== With 100ms netem delay ==="
ping -c 5 127.0.0.1

# The min/avg/max should all be around 200ms now
```

---

## Task 3 — Test Delay with Jitter

```bash
# Change to 100ms delay with ±20ms jitter
tc qdisc change dev lo root netem delay 100ms 20ms

# Test: you should see varying RTTs (roughly 160-240ms)
echo "=== With 100ms ± 20ms jitter ==="
ping -c 10 127.0.0.1

# Show current qdisc configuration
tc qdisc show dev lo

# Show stats
tc -s qdisc show dev lo
```

---

## Task 4 — Add Packet Loss Simulation

```bash
# Change to 20% packet loss with no delay
tc qdisc change dev lo root netem loss 20%

# Ping 20 times — expect ~4 dropped packets
echo "=== With 20% packet loss ==="
ping -c 20 127.0.0.1

# Show packet loss statistics from tc
tc -s qdisc show dev lo
```

Observe the `dropped` counter in the `tc -s qdisc show` output.

```bash
# Try combined: delay + loss
tc qdisc change dev lo root netem delay 50ms loss 10%
ping -c 15 127.0.0.1
tc -s qdisc show dev lo
```

---

## Task 5 — Remove netem and Verify

```bash
# Remove netem from loopback
tc qdisc del dev lo root

# Verify it's gone
tc qdisc show dev lo

# Ping again — should return to sub-millisecond RTT
echo "=== After removing netem ==="
ping -c 5 127.0.0.1
```

---

## Task 6 — Add Token Bucket Rate Limit

```bash
# Limit loopback to 512 kbit/s
tc qdisc add dev lo root tbf rate 512kbit burst 16kbit latency 400ms

# Show the tbf qdisc
tc qdisc show dev lo
tc -s qdisc show dev lo

# Test with a transfer (dd to /dev/null via nc on loopback)
# Start a listener
nc -l -p 19876 > /dev/null &
BGPID=$!

# Send 2 MB and time it (should take ~32 seconds at 512 kbit/s)
# But for a quick test, send 100 KB and see the rate
time dd if=/dev/zero bs=1K count=100 2>/dev/null | nc 127.0.0.1 19876

wait $BGPID 2>/dev/null

# Remove rate limit
tc qdisc del dev lo root
```

---

## Task 7 — Write a Fault Injection Helper Script

```bash
cat > ~/practice/tc/netfault.sh << 'SCRIPT'
#!/bin/bash
# netfault.sh — inject / clear network faults on an interface for testing

IFACE="${1:-lo}"
ACTION="${2:-status}"

case "$ACTION" in
    slow-wan)
        # Simulate a WAN link: 100ms delay, 1% loss
        tc qdisc replace dev "$IFACE" root netem delay 100ms 10ms loss 1%
        echo "Injected: slow-wan (100ms±10ms, 1% loss) on $IFACE"
        ;;
    flaky)
        # Simulate a flaky connection: high jitter, lots of loss
        tc qdisc replace dev "$IFACE" root netem delay 50ms 30ms loss 15% duplicate 2%
        echo "Injected: flaky (50ms±30ms, 15% loss, 2% dup) on $IFACE"
        ;;
    loss-only)
        # Just packet loss
        tc qdisc replace dev "$IFACE" root netem loss "${3:-5}%"
        echo "Injected: ${3:-5}% packet loss on $IFACE"
        ;;
    delay-only)
        # Just delay
        tc qdisc replace dev "$IFACE" root netem delay "${3:-100ms}"
        echo "Injected: ${3:-100ms} delay on $IFACE"
        ;;
    rate-limit)
        # Rate limit using TBF
        RATE="${3:-1mbit}"
        tc qdisc replace dev "$IFACE" root tbf rate "$RATE" burst 32kbit latency 400ms
        echo "Injected: rate limit $RATE on $IFACE"
        ;;
    outage)
        # Simulate complete outage (100% loss)
        tc qdisc replace dev "$IFACE" root netem loss 100%
        echo "Injected: complete outage (100% loss) on $IFACE"
        ;;
    clear)
        if tc qdisc del dev "$IFACE" root 2>/dev/null; then
            echo "Cleared all qdiscs on $IFACE"
        else
            echo "No custom qdisc to clear on $IFACE"
        fi
        ;;
    status)
        echo "=== qdisc status for $IFACE ==="
        tc -s qdisc show dev "$IFACE"
        ;;
    *)
        echo "Usage: $0 <iface> <slow-wan|flaky|loss-only [%]|delay-only [time]|rate-limit [rate]|outage|clear|status>"
        echo "  iface default: lo"
        exit 1
        ;;
esac
SCRIPT

chmod +x ~/practice/tc/netfault.sh

# Test the script
echo "=== Testing netfault.sh ==="
bash ~/practice/tc/netfault.sh lo status

# Inject and test
bash ~/practice/tc/netfault.sh lo slow-wan
tc qdisc show dev lo
ping -c 5 127.0.0.1
bash ~/practice/tc/netfault.sh lo clear
tc qdisc show dev lo
```

---

## Task 8 — Write a tc Stats Summary Script

```bash
cat > ~/practice/tc/tc_stats.sh << 'SCRIPT'
#!/bin/bash
# tc_stats.sh — summarise qdisc statistics across all interfaces

echo "=== Traffic Control Statistics ==="
echo ""

ip link show | grep -E '^[0-9]+:' | awk -F': ' '{print $2}' | awk '{print $1}' | \
while read -r iface; do
    OUTPUT=$(tc -s qdisc show dev "$iface" 2>/dev/null)
    if [ -n "$OUTPUT" ]; then
        echo "--- Interface: $iface ---"
        echo "$OUTPUT"
        echo ""
    fi
done
SCRIPT

chmod +x ~/practice/tc/tc_stats.sh
bash ~/practice/tc/tc_stats.sh
```

---

## Task 9 — Simulate an Outage and Test Timeout Behaviour

```bash
# Inject 100% packet loss on loopback
bash ~/practice/tc/netfault.sh lo outage

echo "=== Connection with 100% loss (should timeout) ==="

# Try to ping — should show 100% packet loss
ping -c 5 -W 1 127.0.0.1

# nc with short timeout should fail quickly
nc -w 2 127.0.0.1 19999 2>&1 && echo "connected (unexpected)" || echo "timed out (expected)"

# Restore
bash ~/practice/tc/netfault.sh lo clear

# Verify restored
ping -c 3 127.0.0.1
```

---

## Verification

```bash
# Ensure loopback is clean before ending
tc qdisc del dev lo root 2>/dev/null; tc qdisc show dev lo

# List practice files
ls -la ~/practice/tc/

# Run scripts one final time
bash ~/practice/tc/tc_stats.sh
bash ~/practice/tc/netfault.sh lo status
```
