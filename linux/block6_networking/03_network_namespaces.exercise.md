# Exercise: Network Namespaces

## Setup

```bash
mkdir -p ~/practice
```

## Task 1: List Existing Network Namespaces

```bash
# List named network namespaces
ip netns list

# List all net namespaces (including unnamed/container ones)
lsns -t net 2>/dev/null || lsns | grep net

# Check your current network namespace
readlink /proc/$$/ns/net
```

## Task 2: Create a Network Namespace

```bash
# Create a new isolated network namespace
sudo ip netns add myns

# Verify it was created
ip netns list

# Look at what's in the new namespace
sudo ip netns exec myns ip link show
# Should only show lo interface (and it's DOWN)
```

## Task 3: Create a veth Pair and Connect to the Namespace

```bash
# Create a veth pair
sudo ip link add veth-host type veth peer name veth-ns

# Verify both ends exist in the host
ip link show veth-host
ip link show veth-ns

# Move one end into myns
sudo ip link set veth-ns netns myns

# Verify veth-ns is now in the namespace
sudo ip netns exec myns ip link show

# It should no longer be visible on the host
ip link show veth-ns 2>&1 || echo "veth-ns not in host namespace (correct!)"
```

## Task 4: Configure IPs and Test Connectivity

```bash
# Assign IP to host-side veth
sudo ip addr add 10.100.0.1/24 dev veth-host

# Assign IP to namespace-side veth
sudo ip netns exec myns ip addr add 10.100.0.2/24 dev veth-ns

# Bring interfaces up
sudo ip link set veth-host up
sudo ip netns exec myns ip link set veth-ns up
sudo ip netns exec myns ip link set lo up

# Test connectivity from host to namespace
ping -c 2 10.100.0.2

# Test from namespace to host
sudo ip netns exec myns ping -c 2 10.100.0.1
```

Record success:
```bash
echo "netns test completed at $(date)" > ~/practice/netns_done.txt
echo "Host: 10.100.0.1 <-> Namespace: 10.100.0.2" >> ~/practice/netns_done.txt
```

## Task 5: Inspect the Isolated Namespace

```bash
# Routing table inside the namespace
sudo ip netns exec myns ip route

# Confirm isolation: run ifconfig inside namespace
sudo ip netns exec myns bash -c 'ip addr; echo "---"; ip route'
```

## Task 6: Cleanup

```bash
sudo ip link del veth-host  # removes both ends of the veth pair
sudo ip netns del myns
ip netns list  # should be empty now (or not include myns)
```

## Expected Outcome

- `~/practice/netns_done.txt` exists OR the veth pair exists on the system
- You created a network namespace, connected it with a veth pair, and pinged across
- You understand that each namespace has its own isolated network stack
