# Traffic Control (tc) and Network Fault Injection with netem

## Overview

`tc` (Traffic Control) is the Linux kernel's packet scheduling subsystem. It gives you precise control over how packets are queued, scheduled, shaped, and emitted from a network interface. For SREs, the most useful capability is **netem** — the Network Emulator — which lets you inject artificial delay, packet loss, duplication, corruption, and reordering into any interface. This is invaluable for:

- Testing how your application handles real network conditions (latency, packet loss)
- Reproducing WAN or poor-WiFi conditions in a lab
- Chaos engineering: validating retry logic, timeouts, and circuit breakers
- Pre-production testing of distributed systems before deploying across data centres

---

## Core Concepts

### Qdisc (Queuing Discipline)

A **qdisc** is the kernel object attached to a network interface that controls how packets are buffered and transmitted. Every interface has at least one qdisc. The default is `pfifo_fast` (or `fq_codel` on modern kernels), which is a simple first-in-first-out queue.

```
Application
    │
    ▼
Kernel TCP/IP stack
    │
    ▼
qdisc (pfifo_fast / netem / tbf / htb / ...)
    │
    ▼
Network driver
    │
    ▼
Physical/virtual interface (eth0, lo, veth...)
```

### Classes

Some qdiscs (like `htb`) support **classes** — sub-queues with their own bandwidth allocation. Leaf classes contain an inner qdisc.

### Filters

**Filters** attach to qdiscs or classes and classify packets (by IP, port, DSCP mark, etc.) into specific classes for differential treatment.

### Handles

Every qdisc and class has a **handle** in the form `major:minor`. The root qdisc typically gets `1:0`, and classes are `1:1`, `1:2`, etc.

---

## Basic tc Commands

```bash
# Show qdiscs on all interfaces
tc qdisc show

# Show qdiscs on a specific interface
tc qdisc show dev eth0

# Show classes (only relevant for classful qdiscs like htb)
tc class show dev eth0

# Show filters
tc filter show dev eth0

# Show statistics for a qdisc
tc -s qdisc show dev eth0
```

---

## netem — Network Emulator

`netem` is a qdisc that adds configurable impairments to packets as they are emitted. It is the standard tool for network fault injection on Linux.

### Adding netem to an Interface

```bash
# Add 100ms delay to all outgoing packets on eth0
tc qdisc add dev eth0 root netem delay 100ms

# Replace an existing qdisc (use 'change' instead of 'add' if one already exists)
tc qdisc change dev eth0 root netem delay 200ms

# Remove netem
tc qdisc del dev eth0 root
```

### Delay

```bash
# Fixed 100ms delay
tc qdisc add dev eth0 root netem delay 100ms

# 100ms delay with ±10ms jitter (uniform distribution)
tc qdisc add dev eth0 root netem delay 100ms 10ms

# 100ms ±10ms with 25% correlation between successive packets
tc qdisc add dev eth0 root netem delay 100ms 10ms 25%

# Normal distribution of delay (more realistic)
tc qdisc add dev eth0 root netem delay 100ms 10ms distribution normal
```

Available distributions: `uniform`, `normal`, `pareto`, `paretonormal`

### Packet Loss

```bash
# Drop 5% of packets (uniformly random)
tc qdisc add dev eth0 root netem loss 5%

# 10% loss with 25% correlation (simulates bursty loss, more realistic)
tc qdisc add dev eth0 root netem loss 10% 25%

# Gilbert-Elliott model (more realistic burst loss)
tc qdisc add dev eth0 root netem loss gemodel 5% 10% 70% 0.5%
```

### Duplication

```bash
# Duplicate 1% of packets
tc qdisc add dev eth0 root netem duplicate 1%
```

### Corruption (bit errors)

```bash
# Randomly corrupt 0.1% of packets
tc qdisc add dev eth0 root netem corrupt 0.1%
```

### Packet Reordering

```bash
# Reorder 10% of packets with 25% correlation (requires a base delay)
tc qdisc add dev eth0 root netem delay 100ms reorder 10% 25%
```

### Combining Impairments

```bash
# 100ms delay + 5% loss + 1% duplication
tc qdisc add dev eth0 root netem delay 100ms loss 5% duplicate 1%

# WAN simulation: 50ms delay, 2% loss, 0.1% corruption
tc qdisc add dev eth0 root netem delay 50ms 5ms loss 2% corrupt 0.1%
```

### Updating and Removing

```bash
# Update existing netem (change replaces parameters atomically)
tc qdisc change dev eth0 root netem delay 200ms

# Remove netem
tc qdisc del dev eth0 root

# Verify it is removed
tc qdisc show dev eth0
```

---

## Testing netem Effects

### Testing Delay with Ping

```bash
# Add 100ms delay to loopback
tc qdisc add dev lo root netem delay 100ms

# Verify with ping (RTT should jump to ~200ms: 100ms each direction)
ping -c 5 127.0.0.1

# Remove
tc qdisc del dev lo root

# Verify restored (fast RTT)
ping -c 3 127.0.0.1
```

### Testing Loss

```bash
# Add 20% loss to loopback
tc qdisc add dev lo root netem loss 20%

# Ping and observe dropped packets
ping -c 20 127.0.0.1

# Remove
tc qdisc del dev lo root
```

---

## Rate Limiting

### TBF — Token Bucket Filter

`tbf` is a simple rate limiter. Tokens accumulate in a bucket at the configured rate; each byte sent consumes a token. When the bucket is empty, packets are queued or dropped.

```bash
# Limit to 1 Mbit/s with a burst of 32 KiB
tc qdisc add dev eth0 root tbf rate 1mbit burst 32kbit latency 400ms

# Parameters:
#   rate      — sustained rate (bits/sec): 1mbit, 1gbit, 1kbit
#   burst     — maximum burst size (handles microbursts)
#   latency   — maximum delay packets spend in the queue
```

```bash
# Change rate
tc qdisc change dev eth0 root tbf rate 10mbit burst 128kbit latency 100ms

# Remove
tc qdisc del dev eth0 root
```

### HTB — Hierarchical Token Bucket

`htb` handles multiple traffic classes with guaranteed and maximum rates, priority, and borrowing:

```bash
# Create HTB root qdisc
tc qdisc add dev eth0 root handle 1:0 htb default 10

# Create a class: guaranteed 1 Mbit/s, maximum 10 Mbit/s
tc class add dev eth0 parent 1:0 classid 1:10 htb rate 1mbit ceil 10mbit

# Create a higher-priority class for SSH
tc class add dev eth0 parent 1:0 classid 1:20 htb rate 1mbit ceil 10mbit prio 1

# Add a filter: SSH traffic goes to high-priority class
tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 \
  match ip dport 22 0xffff flowid 1:20

# Show the hierarchy
tc class show dev eth0

# Remove everything
tc qdisc del dev eth0 root
```

HTB is used for bandwidth management (ISP shaping, QoS), not just testing.

---

## tc Statistics

```bash
# Show qdisc stats including packet and byte counts
tc -s qdisc show dev eth0

# Show class stats
tc -s class show dev eth0

# Useful for checking how many packets were dropped by a qdisc
tc -s qdisc show | grep -A4 netem
```

Example output:

```
qdisc netem 8001: root refcnt 2 limit 1000 delay 100ms
 Sent 12345 bytes 100 pkt (dropped 5, overlimits 0 requeues 0)
 backlog 0b 0p requeues 0
```

The `dropped` counter shows packets discarded due to loss rules or queue overflow.

---

## Fault Injection Helper Script

A reusable script for common fault injection scenarios:

```bash
#!/bin/bash
# netfault.sh — inject / clear network faults for testing

IFACE="${1:-eth0}"
ACTION="${2:-status}"

case "$ACTION" in
    slow-wan)
        tc qdisc replace dev "$IFACE" root netem delay 100ms 10ms loss 1%
        echo "Injected: 100ms delay + 1% loss on $IFACE"
        ;;
    flaky)
        tc qdisc replace dev "$IFACE" root netem delay 50ms 20ms loss 15% duplicate 2%
        echo "Injected: flaky link (50ms±20ms, 15% loss, 2% dup) on $IFACE"
        ;;
    slow)
        tc qdisc replace dev "$IFACE" root tbf rate 512kbit burst 16kbit latency 400ms
        echo "Injected: rate limit 512 kbit/s on $IFACE"
        ;;
    clear)
        tc qdisc del dev "$IFACE" root 2>/dev/null && \
          echo "Cleared all qdiscs on $IFACE" || \
          echo "No custom qdisc to clear on $IFACE"
        ;;
    status)
        echo "=== qdisc on $IFACE ==="
        tc -s qdisc show dev "$IFACE"
        ;;
    *)
        echo "Usage: $0 <iface> <slow-wan|flaky|slow|clear|status>"
        exit 1
        ;;
esac
```

Usage:

```bash
./netfault.sh lo slow-wan    # inject WAN conditions on loopback
./netfault.sh lo clear       # restore normal behaviour
./netfault.sh eth0 flaky     # chaos test on eth0
```

---

## Practical Patterns

### Simulating a Cross-Region Link

```bash
# US East ↔ EU West: ~80ms, small jitter, ~0.05% loss
tc qdisc add dev eth0 root netem delay 80ms 5ms loss 0.05%
```

### Simulating 4G Mobile

```bash
# 4G: ~50ms delay, 5% jitter, occasional loss
tc qdisc add dev eth0 root netem delay 50ms 20ms 30% loss 2% corrupt 0.01%
```

### Simulating Complete Outage (100% loss)

```bash
tc qdisc add dev eth0 root netem loss 100%
# Test your retry/timeout logic
tc qdisc del dev eth0 root
```

### Validating Connection Timeout Settings

```bash
# Add 5 second delay — reveals which apps have wrong timeouts
tc qdisc add dev eth0 root netem delay 5000ms
# Run your app or curl
tc qdisc del dev eth0 root
```

---

## Common Issues and Gotchas

| Problem | Cause | Fix |
|---------|-------|-----|
| `RTNETLINK answers: File exists` | qdisc already attached | Use `change` instead of `add`, or `del` first |
| netem on loopback affects both send and receive | lo is full-duplex but netem applies at egress | RTT is 2× the configured delay |
| `tc` not found | `iproute2` package not installed | `apt-get install -y iproute2` |
| Rate limiting not taking effect | Wrong units | `tc` uses bits (not bytes): `1mbit` = 1 Mbit/s |
| Delay applies to all traffic | netem is classless | Use HTB + netem on a class to target specific flows |
| Forgot to clean up | Left netem running after testing | Always script cleanup; check `tc qdisc show` before committing |

---

## Quick Reference

```bash
# Show all qdiscs
tc qdisc show

# Add 100ms delay to interface
tc qdisc add dev IFACE root netem delay 100ms

# Add 5% packet loss
tc qdisc add dev IFACE root netem loss 5%

# Combined: delay + loss
tc qdisc add dev IFACE root netem delay 100ms loss 5%

# Rate limit to 1 Mbit/s
tc qdisc add dev IFACE root tbf rate 1mbit burst 32kbit latency 400ms

# Remove all impairment
tc qdisc del dev IFACE root

# Check stats
tc -s qdisc show dev IFACE

# Update existing rule
tc qdisc change dev IFACE root netem delay 200ms
```

## Further Reading

- [tc(8) man page](https://man7.org/linux/man-pages/man8/tc.8.html) — The authoritative reference for the `tc` tool covering qdisc, class, and filter management — the foundation for all commands in this lesson.
- [tc-netem(8) man page](https://man7.org/linux/man-pages/man8/tc-netem.8.html) — Complete netem parameter reference including Gilbert-Elliott loss models, reordering correlation, the statistical delay distributions (`normal`, `pareto`, `paretonormal`), and the `lhist` parameter.
- [Linux Traffic Control HOWTO](https://tldp.org/HOWTO/Traffic-Control-HOWTO/) — In-depth guide to tc queuing disciplines, classful vs classless qdiscs, HTB configuration, and filter-based traffic classification — essential background for the rate limiting section.
- [Linux Advanced Routing and Traffic Control](https://lartc.org/) — The comprehensive LARTC book covering tc, CBQ, HTB, TBF, and policy routing — the most thorough free reference for understanding tc's full capability beyond netem.
