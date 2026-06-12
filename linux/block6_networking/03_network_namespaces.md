# Network Namespaces

## What Are Network Namespaces?

A **network namespace** is an isolated copy of the Linux networking stack. Each namespace has its own:
- Network interfaces
- IP addresses
- Routing tables
- iptables rules
- `/proc/net/` directory
- Sockets and connections

This is the mechanism Docker and Kubernetes use to give each container its own network. It's also used for network testing, VPNs, and multi-tenant networking.

The `lo` interface (loopback) exists in every namespace but must be brought up manually in new ones.

## Managing Namespaces with ip netns

```bash
# Create a new network namespace
sudo ip netns add blue

# List network namespaces
ip netns list
ls /var/run/netns/

# Delete a namespace
sudo ip netns del blue

# Execute a command inside a namespace
sudo ip netns exec blue ip addr show
# Shows only loopback (DOWN) — completely isolated

# Run a shell inside a namespace
sudo ip netns exec blue bash
# Now all networking commands run in "blue"
exit
```

## veth Pairs: Connecting Namespaces

A **veth pair** is a virtual ethernet cable: two interfaces connected together. Whatever you send into one end comes out the other. They're used to connect a network namespace to the host (or to another namespace).

```bash
# Create a veth pair: veth0 <-> veth1
sudo ip link add veth0 type veth peer name veth1

# Both appear in the default namespace
ip link show veth0
ip link show veth1

# Move one end into a namespace
sudo ip link set veth1 netns blue

# Verify veth1 is now only visible inside "blue"
ip link show veth1          # Not found in host
sudo ip netns exec blue ip link show veth1   # Found here
```

## Full Two-Namespace Setup with Connectivity

```bash
# 1. Create a namespace
sudo ip netns add blue

# 2. Create a veth pair
sudo ip link add veth-host type veth peer name veth-blue

# 3. Move one end into the namespace
sudo ip link set veth-blue netns blue

# 4. Assign IP addresses
sudo ip addr add 10.200.0.1/24 dev veth-host
sudo ip netns exec blue ip addr add 10.200.0.2/24 dev veth-blue

# 5. Bring both interfaces up
sudo ip link set veth-host up
sudo ip netns exec blue ip link set veth-blue up
sudo ip netns exec blue ip link set lo up

# 6. Test connectivity
ping -c 3 10.200.0.2               # host → namespace
sudo ip netns exec blue ping -c 3 10.200.0.1  # namespace → host

# 7. Cleanup
sudo ip link del veth-host          # deletes both ends of the pair
sudo ip netns del blue
```

## How Docker Uses This Pattern

When Docker starts a container, it:
1. Creates a network namespace for the container
2. Creates a veth pair
3. Puts one end in the container namespace (renamed to `eth0`)
4. Puts the other end on a bridge (`docker0`) in the host namespace
5. Assigns IP addresses and routes
6. Adds iptables/NAT rules for external connectivity

```bash
# See container network namespace
docker run -d --name demo nginx
PID=$(docker inspect -f '{{.State.Pid}}' demo)

# Compare host namespaces with container's
ip link show
sudo nsenter -t $PID --net ip link show   # only lo and eth0

docker stop demo && docker rm demo
```

## Examining Namespaces

```bash
# List all network namespaces with their PIDs
ip netns list

# Show namespace of a specific process
ip netns identify $PID 2>/dev/null

# List all namespaces (including unnamed ones created by containers)
lsns -t net

# Namespace inode for current process
readlink /proc/$$/ns/net
```

## Practical Use: Testing Without Affecting Production

Network namespaces are ideal for testing firewall rules, routing configurations, and network services in isolation without risking the host:

```bash
# Create an isolated test environment
sudo ip netns add testenv
sudo ip netns exec testenv bash --norc

# Inside testenv: lo is there but DOWN
ip link
ip link set lo up
ip addr add 127.0.0.1/8 dev lo

# Run a local web server safely
python3 -m http.server 8080 &
curl http://127.0.0.1:8080

# Nothing from the outside world can reach this
exit  # Back to host
sudo ip netns del testenv
```

## Further Reading

- [network_namespaces(7) man page](https://man7.org/linux/man-pages/man7/network_namespaces.7.html) — Authoritative documentation on what is isolated per network namespace (interfaces, routing table, iptables rules, sockets) and how `/proc/net/` is scoped to the namespace.
- [ip-netns(8) man page](https://man7.org/linux/man-pages/man8/ip-netns.8.html) — Complete reference for `ip netns add`, `exec`, `del`, and `identify`, including how named namespaces map to bind-mount files in `/var/run/netns/`.
- [LWN: Network namespaces](https://lwn.net/Articles/531114/) — The original LWN article introducing network namespaces, explaining the kernel implementation and use cases that motivated their design.
- [Julia Evans: What even is a container?](https://jvns.ca/blog/2016/10/10/what-even-is-a-container/) — Explains how Docker uses network namespaces and veth pairs to give each container an isolated network stack — directly illustrating the Docker section of this lesson.
