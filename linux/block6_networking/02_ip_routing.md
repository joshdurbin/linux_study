# IP Routing

## What Is Routing?

When a packet leaves your machine, the kernel consults the **routing table** to decide: which interface should send this packet, and where should it go next? The routing table is a list of rules mapping destination networks to next-hop gateways and outgoing interfaces.

## Viewing the Routing Table

```bash
# Show all routes (modern)
ip route show
ip route        # shorthand
ip r            # shortest

# Show IPv6 routes
ip -6 route show

# Legacy equivalent
route -n
netstat -rn
```

### Reading ip route output

```
default via 192.168.1.1 dev eth0 proto dhcp src 192.168.1.100 metric 100
192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.100
```

- `default` — catch-all route for any destination not matched by a more specific route
- `via 192.168.1.1` — next hop (the gateway to send to)
- `dev eth0` — outgoing interface
- `proto dhcp` — route was installed by DHCP
- `proto kernel` — route was auto-created when an address was assigned
- `scope link` — destination is directly reachable (same subnet)
- `metric 100` — route preference; lower metric wins when multiple routes match
- `src 192.168.1.100` — preferred source address for outgoing packets

## The Default Gateway

The `default` route (also written as `0.0.0.0/0`) matches any destination. Packets whose destination doesn't match any specific route are forwarded to the **default gateway**.

```bash
# Show only the default route
ip route show default

# Identify the gateway IP
ip route show default | grep -oP '(?<=via )\S+'
```

## Route Lookup: How Packets Find Their Path

The kernel uses **Longest Prefix Match (LPM)**: the most specific route wins.

```
Destination: 192.168.1.50
Routes checked:
  192.168.1.0/24 — matches! (24 bits match)
  10.0.0.0/8     — doesn't match
  default (0.0.0.0/0) — always matches, but shorter prefix

Result: use 192.168.1.0/24 (longest match)
```

## ip route get: Simulate a Route Lookup

```bash
# Which route would be used to reach 8.8.8.8?
ip route get 8.8.8.8
# 8.8.8.8 via 192.168.1.1 dev eth0 src 192.168.1.100 uid 1000

# Which interface would reach a local host?
ip route get 192.168.1.1
# 192.168.1.1 dev eth0 src 192.168.1.100 uid 1000
```

## Manipulating Routes

```bash
# Add a static route to a network via a gateway
sudo ip route add 10.10.0.0/16 via 192.168.1.254 dev eth0

# Add a route with specific metric (priority)
sudo ip route add 10.10.0.0/16 via 192.168.1.253 metric 200

# Add a blackhole route (drop packets silently)
sudo ip route add blackhole 198.51.100.0/24

# Delete a route
sudo ip route del 10.10.0.0/16

# Replace the default gateway
sudo ip route replace default via 192.168.1.254 dev eth0

# Flush all routes on an interface
sudo ip route flush dev eth0
```

## Policy Routing (ip rule)

Standard routing uses a single table. **Policy routing** allows different routing tables based on source address, packet marks, etc.

```bash
# Show routing policy rules
ip rule show
# 0:      from all lookup local        ← kernel-managed, highest priority
# 32766:  from all lookup main         ← the main table (what ip route shows)
# 32767:  from all lookup default      ← empty fallback table

# Show the "local" table (kernel-managed, for local delivery)
ip route show table local

# Add a rule: packets from 10.0.0.0/24 use table 100
sudo ip rule add from 10.0.0.0/24 table 100
sudo ip route add default via 10.0.0.1 table 100
```

## Useful Routing Commands

```bash
# Verify connectivity to default gateway
ping -c 1 $(ip route show default | awk '/default/ {print $3}')

# Show which interface and source IP would be used
ip route get 1.1.1.1

# Count routes
ip route | wc -l

# Watch route changes in real time
ip monitor route
```

## Routing and IP Forwarding

To forward packets between interfaces (router, NAT box, container host), IP forwarding must be enabled:

```bash
# Check current setting (0 = off, 1 = on)
cat /proc/sys/net/ipv4/ip_forward

# Enable temporarily
sudo sysctl -w net.ipv4.ip_forward=1

# Enable permanently in /etc/sysctl.d/99-forwarding.conf:
# net.ipv4.ip_forward = 1
```

## Further Reading

- [ip-route(8) man page](https://man7.org/linux/man-pages/man8/ip-route.8.html) — The definitive reference for every route attribute (`scope`, `proto`, `metric`, `nexthop`, multipath routes) and all `ip route` subcommands used in this lesson.
- [RFC 791 — Internet Protocol](https://datatracker.ietf.org/doc/html/rfc791) — The foundational IP specification; understanding the header fields (TTL, protocol, addresses) clarifies why routing decisions are made the way they are.
- [Julia Evans: How do network packets get routed?](https://jvns.ca/blog/2022/09/06/send-network-packets/) — Clear walkthrough of how the kernel selects a route for an outgoing packet, including ARP, gateway selection, and how `ip route get` simulates the lookup.
- [Linux IP Routing HOWTO](https://tldp.org/HOWTO/Linux-ip-routing/) — In-depth guide to Linux policy routing including multiple routing tables, `ip rule`, and practical multi-homed server configurations.
- [iproute2 command reference](https://baturin.org/docs/iproute2/) — The routing section covers `ip route`, `ip rule`, and route types (blackhole, prohibit, unreachable) with annotated examples.
