# Exercise: Network Namespaces and Container Networking

Complete the following tasks. Save your notes to `~/practice/container_net_notes.txt`.

## Task 1 — Document veth Pair and Bridge Concepts

```bash
mkdir -p ~/practice
cat > ~/practice/container_net_notes.txt << 'EOF'
Container Network Namespace Notes
===================================
Each container gets its own network namespace.
The namespace has its own: interfaces, routing table, iptables rules, socket table.

veth pair (virtual Ethernet):
  - Two linked virtual interfaces; packets in one end come out the other
  - One end lives inside the container's network namespace
  - Other end attaches to docker0 (host bridge) in the host namespace
  - Create: ip link add veth0 type veth peer name veth1
  - Move to namespace: ip link set veth0 netns <ns>

docker0 bridge:
  - Linux bridge created by Docker on the host
  - Default subnet: 172.17.0.0/16
  - All container veth endpoints attach here
  - Enables container-to-container traffic on the same host

Network namespace files:
  /run/netns/         - named namespaces (ip netns add)
  /proc/<PID>/ns/net  - per-process namespace inode
  lsns -t net         - list all net namespaces
EOF
```

## Task 2 — Inspect Network Interfaces on the Host

Record the host's network interfaces to see docker0 (if Docker is running) or just the regular interfaces:

```bash
echo "" >> ~/practice/container_net_notes.txt
echo "Host network interfaces:" >> ~/practice/container_net_notes.txt
ip -brief addr >> ~/practice/container_net_notes.txt
```

## Task 3 — Record Your Network Namespace Inode

```bash
echo "" >> ~/practice/container_net_notes.txt
echo "Current network namespace inode:" >> ~/practice/container_net_notes.txt
readlink /proc/self/ns/net >> ~/practice/container_net_notes.txt
```

## Task 4 — Document Container-to-External Traffic Flow

Append a description of how container traffic reaches the internet:

```bash
cat >> ~/practice/container_net_notes.txt << 'EOF'

Container-to-External Traffic Flow
-------------------------------------
1. Container sends packet from its veth0 (172.17.0.x)
2. Packet exits through veth1 on docker0 bridge
3. Kernel routes packet to host's external interface
4. iptables MASQUERADE rule rewrites source IP to host IP (SNAT)
5. Reply comes back, iptables rewrites destination IP back to container IP
6. Packet delivered to container through bridge and veth pair

Check the MASQUERADE rule:
  sudo iptables -t nat -L POSTROUTING -n -v
EOF
```

## Task 5 — Document ip netns Commands

```bash
cat >> ~/practice/container_net_notes.txt << 'EOF'

ip netns Commands
-----------------
ip netns add myns              # create named namespace
ip netns list                  # list named namespaces
ip netns exec myns ip addr     # run command inside namespace
ip netns delete myns           # delete named namespace
ip link set eth0 netns myns    # move interface into namespace
lsns -t net                    # list all network namespaces (including unnamed)
EOF
```
