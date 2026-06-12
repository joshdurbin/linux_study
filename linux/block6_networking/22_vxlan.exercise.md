# Exercise: VXLAN — Virtual eXtensible LAN

These exercises use `ip` (from block6/01) and `tcpdump` (from block6/04) to create and inspect VXLAN interfaces. No new tools are required. Root privileges are needed.

---

## Setup

```bash
mkdir -p ~/practice/vxlan
cd ~/practice/vxlan
```

Verify the kernel supports VXLAN:

```bash
# Check for VXLAN kernel module
modinfo vxlan 2>/dev/null | head -5 || echo "vxlan module info not available"

# Try loading it
modprobe vxlan 2>/dev/null && echo "vxlan module loaded" || echo "vxlan module not loadable (may be built-in)"

# Check if the ip link type vxlan command is understood
ip link help vxlan 2>&1 | head -10 || echo "ip link type vxlan not available"
```

---

## Task 1 — Create a VXLAN Interface

```bash
# Create a basic VXLAN interface with VNI 100 on the standard IANA port
ip link add vxlan0 type vxlan id 100 dstport 4789

# Verify it was created
ip link show vxlan0

# Assign an IP address for the overlay network
ip addr add 192.168.100.1/24 dev vxlan0

# Bring it up
ip link set vxlan0 up

# Verify it's up
ip link show vxlan0
ip addr show vxlan0
```

---

## Task 2 — Inspect with ip -d link show

The `-d` flag reveals VXLAN-specific parameters:

```bash
# Show detailed VXLAN interface information
ip -d link show vxlan0

# Grep for key VXLAN fields
ip -d link show vxlan0 | grep vxlan

# Save to file for reference
ip -d link show vxlan0 > ~/practice/vxlan/vxlan0_detail.txt
cat ~/practice/vxlan/vxlan0_detail.txt
```

Identify in the output:
- The VNI (`id`)
- The destination port (`dstport 4789`)
- The MTU (should be 1450 = 1500 - 50 overhead)
- The `ageing` value (FDB entry TTL)

---

## Task 3 — Create a Second VXLAN Interface (Different VNI)

```bash
# Create a second VXLAN with VNI 200 — a separate overlay network
ip link add vxlan1 type vxlan id 200 dstport 4789

ip addr add 192.168.200.1/24 dev vxlan1
ip link set vxlan1 up

# Show all VXLAN interfaces at once
ip link show type vxlan

# Confirm both are up
ip -d link show vxlan0 | grep 'vxlan id'
ip -d link show vxlan1 | grep 'vxlan id'
```

---

## Task 4 — View and Manipulate the FDB

```bash
# Show the FDB for vxlan0
bridge fdb show dev vxlan0

# Show all FDB entries system-wide
bridge fdb show

# Add a static FDB entry (simulating a remote container's MAC at VTEP 10.0.0.2)
bridge fdb add de:ad:be:ef:00:01 dev vxlan0 dst 10.0.0.2

# Add the default flood entry (BUM traffic)
bridge fdb add 00:00:00:00:00:00 dev vxlan0 dst 10.0.0.2

# Show the FDB again — confirm entries were added
bridge fdb show dev vxlan0

# Save FDB snapshot
bridge fdb show dev vxlan0 > ~/practice/vxlan/fdb_snapshot.txt
cat ~/practice/vxlan/fdb_snapshot.txt

# Delete the entries
bridge fdb del de:ad:be:ef:00:01 dev vxlan0 dst 10.0.0.2
bridge fdb del 00:00:00:00:00:00 dev vxlan0 dst 10.0.0.2

# Confirm deletion
bridge fdb show dev vxlan0
```

---

## Task 5 — Docker VXLAN Inspection (if Docker is available)

```bash
# Check if Docker is available
if command -v docker >/dev/null 2>&1; then
    echo "Docker is available"

    # Show any VXLAN interfaces created by Docker
    ip link show type vxlan

    # Inspect Docker networks for overlay type
    docker network ls 2>/dev/null | grep overlay || echo "No overlay networks"

    # If Docker Swarm is active, show overlay network details
    docker network inspect ingress 2>/dev/null | grep -i vxlan || \
      echo "Swarm ingress not available"

    # Show all bridge-type interfaces (Docker uses bridges for overlay)
    ip link show type bridge 2>/dev/null | head -20
else
    echo "Docker not available — skip this task"
fi

# Even without Docker, check for any VXLAN interfaces created by k8s/other tools
ip link show type vxlan
```

---

## Task 6 — Capture VXLAN Traffic Filter with tcpdump

Practice the tcpdump filter syntax for VXLAN (UDP port 4789):

```bash
# Run tcpdump with VXLAN filter in the background for 3 seconds
# (capture on loopback — VXLAN traffic would normally be on eth0)
timeout 3 tcpdump -i any -n -c 10 udp port 4789 > ~/practice/vxlan/vxlan_capture.txt 2>&1 &
TCPDUMP_PID=$!

# Generate some traffic — send a UDP packet to port 4789 on loopback
# (won't be real VXLAN, but exercises the filter)
echo "test" | nc -u -w 1 127.0.0.1 4789 2>/dev/null || true

wait $TCPDUMP_PID 2>/dev/null
cat ~/practice/vxlan/vxlan_capture.txt

# Also test that tcpdump accepts the filter syntax
tcpdump -i lo -n -c 1 udp port 4789 --list-interfaces 2>&1 | head -5 || \
  echo "tcpdump VXLAN filter syntax accepted"

# Run a dry-run to verify filter compiles
tcpdump -d udp port 4789 2>/dev/null | head -5 && echo "VXLAN tcpdump filter compiles OK"
```

---

## Task 7 — Write a VXLAN Topology Inspection Script

```bash
cat > ~/practice/vxlan/vxlan_inspect.sh << 'SCRIPT'
#!/bin/bash
# vxlan_inspect.sh — show all VXLAN interfaces and their configuration

echo "=== VXLAN Topology Inspection ==="
echo "Date: $(date)"
echo ""

# Find all VXLAN interfaces
VXLAN_IFACES=$(ip link show type vxlan 2>/dev/null | \
               grep -E '^[0-9]+:' | awk -F': ' '{print $2}' | awk '{print $1}')

if [ -z "$VXLAN_IFACES" ]; then
    echo "No VXLAN interfaces found."
    echo ""
    echo "To create one: ip link add vxlan0 type vxlan id 100 dstport 4789"
    exit 0
fi

COUNT=0
for iface in $VXLAN_IFACES; do
    COUNT=$((COUNT + 1))
    echo "=== Interface #$COUNT: $iface ==="

    # State and addresses
    STATE=$(ip link show "$iface" 2>/dev/null | grep -oE 'state [A-Z]+' | head -1)
    echo "  State: $STATE"

    ADDRS=$(ip addr show "$iface" 2>/dev/null | awk '/inet /{print $2}')
    if [ -n "$ADDRS" ]; then
        echo "  Addresses: $ADDRS"
    else
        echo "  Addresses: (none assigned)"
    fi

    # VXLAN parameters
    VNI=$(ip -d link show "$iface" 2>/dev/null | grep 'vxlan id' | \
          grep -oE 'id [0-9]+' | awk '{print $2}')
    DSTPORT=$(ip -d link show "$iface" 2>/dev/null | \
              grep -oE 'dstport [0-9]+' | awk '{print $2}')
    LOCAL=$(ip -d link show "$iface" 2>/dev/null | \
            grep -oE 'local [0-9.]+' | awk '{print $2}')
    MTU=$(ip link show "$iface" 2>/dev/null | grep -oE 'mtu [0-9]+' | awk '{print $2}')

    echo "  VNI: ${VNI:-unknown}"
    echo "  Dst Port: ${DSTPORT:-unknown}"
    echo "  Local VTEP: ${LOCAL:-0.0.0.0 (not set)}"
    echo "  MTU: ${MTU:-unknown}"

    # FDB entries
    FDB_COUNT=$(bridge fdb show dev "$iface" 2>/dev/null | wc -l)
    echo "  FDB entries: $FDB_COUNT"
    bridge fdb show dev "$iface" 2>/dev/null | while read -r entry; do
        echo "    $entry"
    done

    echo ""
done

echo "Total VXLAN interfaces: $COUNT"
SCRIPT

chmod +x ~/practice/vxlan/vxlan_inspect.sh
bash ~/practice/vxlan/vxlan_inspect.sh
```

---

## Task 8 — Clean Up

```bash
# Save the final inspection before cleanup
bash ~/practice/vxlan/vxlan_inspect.sh > ~/practice/vxlan/final_topology.txt
cat ~/practice/vxlan/final_topology.txt

# Remove VXLAN interfaces
ip link del vxlan0 2>/dev/null && echo "deleted vxlan0" || echo "vxlan0 already gone"
ip link del vxlan1 2>/dev/null && echo "deleted vxlan1" || echo "vxlan1 already gone"

# Verify clean
ip link show type vxlan
```

---

## Verification

```bash
# Check all expected files exist
ls -la ~/practice/vxlan/

# Re-run the inspection script (should show 0 interfaces after cleanup)
bash ~/practice/vxlan/vxlan_inspect.sh
```
