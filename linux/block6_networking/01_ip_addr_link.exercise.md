# Exercise: ip addr and ip link

## Setup

```bash
mkdir -p ~/practice
```

## Task 1: List All Network Interfaces

```bash
ip link show
```

Note:
- How many interfaces are present?
- Which ones are in UP state?
- What are their MAC addresses?

## Task 2: Examine IP Addresses on All Interfaces

```bash
ip addr show
```

For each interface, identify:
- IPv4 address and subnet mask (CIDR notation)
- IPv6 link-local address
- Interface flags (BROADCAST, LOOPBACK, etc.)

```bash
# IPv4 only
ip -4 addr

# IPv6 only
ip -6 addr
```

## Task 3: Record Interface Information

Save information about all interfaces to a file:

```bash
echo "=== Interface Summary ===" > ~/practice/interfaces.txt
echo "Date: $(date)" >> ~/practice/interfaces.txt
echo "" >> ~/practice/interfaces.txt

ip addr show >> ~/practice/interfaces.txt

echo "" >> ~/practice/interfaces.txt
echo "=== Link Status ===" >> ~/practice/interfaces.txt
ip link show >> ~/practice/interfaces.txt

cat ~/practice/interfaces.txt
```

## Task 4: Check Interface Statistics

```bash
# Show packet counts, errors, drops for each interface
ip -s link show

# Or for a specific interface (use the name from ip link output)
# ip -s link show eth0
```

Look for:
- RX (receive) and TX (transmit) packet counts
- Any errors or dropped packets

## Task 5: Inspect the Loopback Interface

```bash
# Loopback details
ip addr show lo
ip -s link show lo

# Test loopback is working
ping -c 3 127.0.0.1
ping -c 1 ::1 2>/dev/null && echo "IPv6 loopback works"
```

## Task 6: Compare ip addr vs ifconfig (if available)

```bash
# Modern way
ip addr

# Legacy way (may not be installed)
ifconfig 2>/dev/null || echo "ifconfig not installed (that's fine)"
```

## Expected Outcome

- `~/practice/interfaces.txt` exists and contains at least one interface line
- You can identify interface names, states, IP addresses, and MAC addresses
- You understand the difference between `ip link` (layer 2) and `ip addr` (layer 3)
