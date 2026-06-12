# VXLAN — Virtual eXtensible LAN

## Overview

VXLAN (Virtual eXtensible LAN) is a network encapsulation protocol that tunnels Layer 2 (Ethernet) frames inside UDP packets. It was designed to solve the scalability limitations of traditional VLANs in large data centre and cloud environments:

- **VLAN limitation**: 4094 VLANs (12-bit ID) — insufficient for multi-tenant clouds
- **VXLAN**: 16 million virtual networks (24-bit VNI)
- **L2 over L3**: VMs on different physical hosts appear to be on the same Ethernet segment

VXLAN is the foundation of:
- Docker overlay networks
- Kubernetes Flannel (VXLAN backend)
- Kubernetes Calico (VXLAN mode)
- AWS VPC (uses a form of VXLAN internally)
- OpenStack Neutron (VXLAN tenant networks)

Understanding VXLAN helps you debug overlay network issues, interpret `tcpdump` captures, and understand why containers on different hosts can communicate.

---

## How VXLAN Works

### Encapsulation

A VXLAN packet wraps a complete Ethernet frame:

```
Outer Ethernet header  (src/dst MAC of physical hosts)
Outer IP header        (src/dst IP of VTEPs)
Outer UDP header       (dst port 4789)
VXLAN header           (8 bytes: flags + 24-bit VNI)
Inner Ethernet frame   (original L2 frame of the overlay network)
  Inner IP header
  Inner TCP/UDP/etc.
  Payload
```

The overhead is: 14 (Eth) + 20 (IP) + 8 (UDP) + 8 (VXLAN) = **50 bytes per packet**. This is why MTU tuning matters with VXLAN — if the physical network has MTU 1500, your overlay should use 1450 or less.

### VTEP — VXLAN Tunnel Endpoint

A **VTEP** is a network entity (physical NIC, virtual interface, hardware switch) that performs VXLAN encapsulation and decapsulation. In a Linux server:

- The `vxlan0` interface is a software VTEP
- Packets sent into `vxlan0` are encapsulated in UDP and sent to a remote VTEP
- Packets received on UDP port 4789 are decapsulated and delivered to `vxlan0`

### VNI — VXLAN Network Identifier

The 24-bit VNI (similar to a VLAN ID but 16 million values) identifies which virtual network a packet belongs to. Hosts only deliver decapsulated packets to interfaces with the matching VNI.

```
Host A (VTEP 10.0.0.1)               Host B (VTEP 10.0.0.2)
  vxlan0 VNI=100                         vxlan0 VNI=100
  ┌─────────────────┐                   ┌─────────────────┐
  │ Container A     │                   │ Container B     │
  │ IP: 192.168.1.1 │                   │ IP: 192.168.1.2 │
  └────────┬────────┘                   └────────┬────────┘
           │                                     │
     [vxlan0]                              [vxlan0]
           │ encapsulate L2 in UDP              │
     [eth0: 10.0.0.1] ←──────────────→ [eth0: 10.0.0.2]
           │             UDP port 4789          │
     Physical network (L3)
```

Container A and B appear to be on the same Ethernet segment (192.168.1.0/24), even though they are on different physical hosts communicating over IP.

### FDB — Forwarding Database

The FDB maps **inner MAC addresses** (of overlay VMs/containers) to **outer IP addresses** (of VTEPs). When `vxlan0` needs to deliver a frame to a container, it looks up the FDB to find which VTEP's IP to use as the UDP destination.

```
FDB entry:
  Inner MAC: de:ad:be:ef:00:01 → VTEP IP: 10.0.0.2
```

FDB entries can be:
- **Static**: manually added with `bridge fdb add`
- **Dynamic**: learned by the kernel when VXLAN traffic arrives
- **Default/flood**: `00:00:00:00:00:00` entry pointing to a multicast group or unicast VTEP for BUM (Broadcast, Unknown, Multicast) traffic

---

## Creating VXLAN Interfaces

### Basic VXLAN Interface

```bash
# Create a VXLAN interface with VNI 100
# dstport 4789 is the standard IANA VXLAN port
ip link add vxlan0 type vxlan id 100 dstport 4789

# Assign an IP address in the overlay network
ip addr add 192.168.100.1/24 dev vxlan0

# Bring it up
ip link set vxlan0 up

# Show the interface with detailed VXLAN parameters
ip -d link show vxlan0
```

### VXLAN with Unicast Remote VTEP

```bash
# VXLAN interface that sends to a specific remote VTEP
ip link add vxlan10 type vxlan \
    id 10 \
    dev eth0 \            # physical interface to use for encapsulation
    remote 10.0.0.2 \     # default remote VTEP IP
    dstport 4789 \
    local 10.0.0.1        # local VTEP IP (source of outer UDP)
```

### VXLAN with Multicast Flooding

```bash
# Use a multicast group for BUM traffic (requires multicast routing)
ip link add vxlan20 type vxlan \
    id 20 \
    dev eth0 \
    group 239.0.0.20 \    # multicast group for BUM
    dstport 4789
```

### VXLAN Parameters

| Parameter | Description |
|-----------|-------------|
| `id N` | VNI (0 to 16777215) |
| `dstport N` | UDP destination port (standard: 4789) |
| `dev IFACE` | Physical interface to bind to |
| `local IP` | Source IP for encapsulated packets |
| `remote IP` | Default unicast VTEP for flooding |
| `group MCAST` | Multicast group for BUM traffic |
| `learning` | Enable/disable FDB learning (default: on) |
| `nolearning` | Disable FDB learning (use static FDB or control plane) |
| `proxy` | Enable ARP proxy |
| `l2miss` | Emit netlink notifications on L2 misses |
| `l3miss` | Emit netlink notifications on L3 misses |

---

## Inspecting VXLAN Interfaces

### ip -d link show

The `-d` flag shows detailed parameters:

```bash
ip -d link show vxlan0
```

Example output:

```
5: vxlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN
    link/ether 5e:4b:ab:12:34:56 brd ff:ff:ff:ff:ff:ff promiscuity 0
    vxlan id 100 dstport 4789 local 0.0.0.0 ttl auto ageing 300 udpcsum noudp6zerocsumtx noudp6zerocsumrx
```

Key fields: `id` (VNI), `dstport`, `local` (VTEP IP), `ageing` (FDB entry TTL in seconds).

Note the MTU: `vxlan0` typically shows MTU **1450** (1500 - 50 bytes VXLAN overhead).

### Checking the FDB

```bash
# Show FDB for a VXLAN interface
bridge fdb show dev vxlan0

# Show all FDB entries
bridge fdb show

# Filter for VXLAN entries
bridge fdb show | grep dst
```

Example FDB entries:

```
00:00:00:00:00:00 dev vxlan0 dst 10.0.0.2 via eth0 self permanent
de:ad:be:ef:00:01 dev vxlan0 dst 10.0.0.3 self
```

- `00:00:00:00:00:00`: catch-all entry — unknown MACs are flooded to `dst`
- `de:ad:be:ef:00:01`: learned entry — this MAC is at VTEP `10.0.0.3`

### Adding Static FDB Entries

```bash
# Add a static mapping: this MAC lives at VTEP 10.0.0.2
bridge fdb add de:ad:be:ef:00:01 dev vxlan0 dst 10.0.0.2

# Add a default flood entry (for unicast-based networks)
bridge fdb add 00:00:00:00:00:00 dev vxlan0 dst 10.0.0.2

# Delete an FDB entry
bridge fdb del de:ad:be:ef:00:01 dev vxlan0 dst 10.0.0.2
```

---

## VXLAN MTU Considerations

VXLAN adds 50 bytes of overhead. If the physical network MTU is 1500:

- **Overlay MTU should be 1450** (1500 - 50 = 1450)
- Linux automatically sets the VXLAN interface MTU to `underlay_MTU - 50`

For jumbo frames (MTU 9000 on physical):
- Overlay MTU = 8950

```bash
# Check current MTU
ip link show vxlan0 | grep mtu

# Set MTU manually if needed
ip link set vxlan0 mtu 1450
```

---

## Capturing VXLAN Traffic with tcpdump

VXLAN traffic is UDP on port 4789. You can capture it on the physical interface:

```bash
# Capture VXLAN packets on eth0
tcpdump -i eth0 -n udp port 4789

# Capture with full packet dump (see inner L2 frames)
tcpdump -i eth0 -n -X udp port 4789

# Save to file for Wireshark analysis
tcpdump -i eth0 -n -w /tmp/vxlan.pcap udp port 4789

# Capture only VXLAN packets to/from a specific VTEP
tcpdump -i eth0 -n udp port 4789 and host 10.0.0.2
```

On the VXLAN interface itself (decapsulated traffic):

```bash
# See the inner Ethernet frames (post-decapsulation)
tcpdump -i vxlan0 -n
```

---

## Docker Overlay Networks and VXLAN

Docker overlay networks use VXLAN under the hood. When you create an overlay network with Docker Swarm:

```bash
# Create an overlay network (Swarm required)
docker network create --driver overlay my-overlay

# Inspect the network
docker network inspect my-overlay
```

Docker creates a `vxlan0` or `vx-<id>` interface for each overlay network. You can find these with:

```bash
# Show VXLAN interfaces created by Docker
ip -d link show | grep -A3 vxlan

# Or list all link types
ip link show type vxlan
```

Docker VXLAN details:
- VNI: Docker assigns a unique VNI per overlay network
- Port: Docker uses **4789** (IANA standard) in recent versions
- Encryption: Docker Swarm supports `--opt encrypted` (uses IPsec + VXLAN)

---

## Kubernetes VXLAN (Flannel / Calico)

### Flannel VXLAN backend

Flannel creates a `flannel.1` interface:

```bash
# On a Kubernetes worker node
ip -d link show flannel.1
bridge fdb show dev flannel.1
```

Flannel uses kernel VXLAN with:
- `learning off` (no L2 learning — Flannel daemon manages FDB directly)
- `proxy on` (Flannel answers ARP requests itself)
- FDB and ARP entries populated by the Flannel daemon watching etcd/API server

### Calico VXLAN

Calico creates a `vxlan.calico` interface and uses VXLAN for cross-host pod-to-pod traffic when BGP is not available.

---

## VXLAN Troubleshooting

### Checklist

```
1. Is the VXLAN interface up?
   → ip link show vxlan0

2. Is the VNI correct on both endpoints?
   → ip -d link show vxlan0 | grep 'vxlan id'

3. Is the VTEP IP reachable?
   → ping <remote VTEP IP>

4. Is UDP 4789 blocked by a firewall?
   → tcpdump -i eth0 udp port 4789

5. Are FDB entries correct?
   → bridge fdb show dev vxlan0

6. MTU mismatch causing fragmentation/drops?
   → ip link show vxlan0 (check mtu field)
   → ping -s 1400 -M do <overlay IP>   # DF-bit ping to test path MTU

7. Is iptables dropping decapsulated traffic?
   → iptables -L -v -n (look for DROP rules on vxlan0)
```

### Common Issues

| Symptom | Likely Cause |
|---------|-------------|
| Overlay pings fail, underlay pings work | VNI mismatch, or VTEP IP wrong in FDB |
| Random packet loss on overlay | MTU problem — overlay MTU too large |
| VXLAN packets captured on eth0 but no delivery | iptables DROP rule on vxlan0 or FORWARD chain |
| High latency on overlay | VTEP route going through wrong interface |
| Docker overlay containers can't talk cross-host | Docker Swarm not joined, or port 4789 blocked |

---

## VXLAN Topology Inspection Script

```bash
#!/bin/bash
# vxlan_inspect.sh — show all VXLAN interfaces and their configuration

echo "=== VXLAN Interfaces ==="
echo ""

# Find all VXLAN interfaces
VXLAN_IFACES=$(ip link show type vxlan 2>/dev/null | \
               grep -E '^[0-9]+:' | awk -F': ' '{print $2}' | awk '{print $1}')

if [ -z "$VXLAN_IFACES" ]; then
    echo "No VXLAN interfaces found."
    exit 0
fi

for iface in $VXLAN_IFACES; do
    echo "--- Interface: $iface ---"

    # Show interface state and IP
    ip addr show "$iface" 2>/dev/null | grep -E 'state|inet'

    # Show detailed VXLAN parameters
    echo "VXLAN parameters:"
    ip -d link show "$iface" 2>/dev/null | grep vxlan | \
      sed 's/    /  /g'

    # Show FDB
    echo "FDB entries:"
    bridge fdb show dev "$iface" 2>/dev/null | \
      grep -v '00:00:00:00:00:00' | head -10 || echo "  (none)"

    echo ""
done
```

---

## Quick Reference

```bash
# Create VXLAN interface
ip link add vxlan0 type vxlan id 100 dstport 4789

# Inspect VXLAN details
ip -d link show vxlan0

# Show FDB
bridge fdb show dev vxlan0

# Add static FDB entry
bridge fdb add <MAC> dev vxlan0 dst <VTEP-IP>

# Capture VXLAN traffic
tcpdump -i eth0 -n udp port 4789

# List all VXLAN interfaces
ip link show type vxlan

# Delete VXLAN interface
ip link del vxlan0
```

## Further Reading

- [RFC 7348 — VXLAN](https://datatracker.ietf.org/doc/html/rfc7348) — The VXLAN protocol specification defining the 8-byte VXLAN header, VNI format, VTEP behavior, and the UDP port 4789 standard shown in the encapsulation diagram.
- [ip-link(8) VXLAN section](https://man7.org/linux/man-pages/man8/ip-link.8.html) — Documents every VXLAN parameter for `ip link add … type vxlan` including `id`, `dstport`, `learning`, `l2miss`, `l3miss`, `proxy`, and `nolearning` with valid ranges.
- [Julia Evans: How do Kubernetes and Docker create IP addresses?](https://jvns.ca/blog/2021/11/04/how-do-kubernetes-and-docker-create-ip-addresses/) — Explains how Flannel and Calico use VXLAN FDB entries and ARP proxy to give pods routable IPs across hosts — directly illustrating the Kubernetes VXLAN section.
- [kernel.org: VXLAN documentation](https://www.kernel.org/doc/html/latest/networking/vxlan.html) — The kernel's VXLAN driver documentation explaining the FDB learning process, multicast vs unicast flooding modes, and the `ageing` timer that controls FDB entry lifetimes.
