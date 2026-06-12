# Network Namespaces and Container Networking

## What Is a Network Namespace?

A network namespace gives a process its own isolated view of the network stack: its own network interfaces, routing table, iptables rules, and socket table. Two processes in different network namespaces cannot directly communicate without an explicit link between the namespaces.

Every container runtime (Docker, Podman, containerd) creates a new network namespace per container.

## The veth Pair

A **virtual Ethernet pair** (veth) is a pair of linked virtual interfaces. Anything sent into one end comes out the other. Container runtimes use veth pairs to connect a container's network namespace to the host:

- One end (`veth0` or similar) lives **inside the container's network namespace**
- The other end (`veth1` or `vethXXXXXX`) lives in the **host namespace** and is attached to a bridge

```bash
# Create a veth pair
sudo ip link add veth0 type veth peer name veth1

# Move veth0 into a network namespace
sudo ip netns add myns
sudo ip link set veth0 netns myns

# Configure the container side
sudo ip netns exec myns ip addr add 172.17.0.2/16 dev veth0
sudo ip netns exec myns ip link set veth0 up
sudo ip netns exec myns ip link set lo up

# Configure the host side and attach to bridge
sudo ip link set veth1 master docker0
sudo ip link set veth1 up
```

## The docker0 Bridge

Docker creates a Linux bridge interface called `docker0` on the host. All container veth endpoints attach to this bridge, enabling container-to-container communication on the same host.

```bash
# Inspect the docker0 bridge
ip addr show docker0
ip link show master docker0      # show interfaces attached to docker0
brctl show docker0               # (if bridge-utils installed)
```

Default Docker bridge subnet: `172.17.0.0/16`. Each container gets an address in this range.

## Network Namespace Files

```bash
# Named network namespaces appear here (created with ip netns add)
ls /run/netns/

# Each process's network namespace
readlink /proc/<PID>/ns/net

# List all network namespaces
lsns -t net

# Execute a command inside a named namespace
sudo ip netns exec myns ip addr
```

## Container-to-Container Communication

1. **Same host, same bridge**: Packets flow through docker0 without leaving the host.
2. **Different hosts**: Requires overlay networking (VXLAN, Geneve) — the CNI layer in Kubernetes.
3. **Container-to-host**: Routed through the veth pair and bridge; iptables masquerades traffic for external access.

## Container-to-External Communication

Docker inserts an iptables MASQUERADE rule so that container traffic leaving the host appears to come from the host's IP:

```bash
# View Docker's iptables NAT rules
sudo iptables -t nat -L POSTROUTING -n -v
# Look for: MASQUERADE  all  172.17.0.0/16  !172.17.0.0/16
```

## Inspecting a Running Container's Network

```bash
# Get the container's PID
docker inspect --format '{{.State.Pid}}' <container>

# See the container's network interfaces from host
sudo nsenter -t <PID> -n ip addr

# Check the network namespace inode
readlink /proc/<PID>/ns/net
```

## Key Takeaways

- Each container gets its own network namespace with an isolated network stack.
- veth pairs bridge container namespaces to the host bridge (docker0).
- docker0 is a Linux bridge; all container-side veth ends attach to it.
- Named namespaces live in `/run/netns/`; process namespaces are accessed via `/proc/PID/ns/net`.
- External traffic uses iptables MASQUERADE (SNAT) on the host.

## Further Reading

- [network_namespaces(7) man page](https://man7.org/linux/man-pages/man7/network_namespaces.7.html) — Documents which network resources are isolated per namespace (interfaces, routing table, iptables rules, socket table) and restrictions on sharing resources across namespace boundaries.
- [veth(4) man page](https://man7.org/linux/man-pages/man4/veth.4.html) — Documents veth pair creation, the peer interface naming convention, and the `ip link add … type veth peer name` syntax used to build the container-to-bridge connection in this lesson.
- [Julia Evans: A container networking overview](https://jvns.ca/blog/2022/03/24/a-container-networking-overview/) — Explains how docker0, veth pairs, iptables MASQUERADE, and network namespaces combine to give containers network access — a clear walkthrough of exactly what this lesson covers.
- [Docker networking documentation](https://docs.docker.com/network/) — Docker's official networking guide covering bridge, host, overlay, and macvlan drivers; explains how docker0 is created and how `docker network create` maps to the veth/namespace primitives in this lesson.
