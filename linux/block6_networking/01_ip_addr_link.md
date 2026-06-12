# ip addr and ip link: Network Interface Management

## The iproute2 Suite

`ip` is the modern replacement for `ifconfig`, `route`, and `arp`. It comes from the **iproute2** package and is the standard tool on all modern Linux distributions. The old `net-tools` package (`ifconfig`, `netstat`, `arp`) is deprecated but still found on many systems.

```bash
# Check iproute2 version
ip -V

# Get help on any subcommand
ip addr help
ip link help
```

## ip link: Layer 2 (Network Interfaces)

`ip link` manages network interfaces at the **link layer** (Layer 2) — it deals with physical and virtual interfaces, their state, and their hardware properties.

```bash
# List all interfaces
ip link show
ip link     # shorthand

# Show a specific interface
ip link show eth0
ip link show lo
```

### Reading ip link output

```
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode DEFAULT group default qlen 1000
    link/ether 00:1a:2b:3c:4d:5e brd ff:ff:ff:ff:ff:ff
```

- `2:` — interface index
- `eth0` — interface name
- `<BROADCAST,MULTICAST,UP,LOWER_UP>` — flags: UP = admin up, LOWER_UP = physical link detected
- `mtu 1500` — Maximum Transmission Unit (bytes)
- `state UP` — operational state
- `link/ether` — MAC address
- `brd ff:ff:ff:ff:ff:ff` — broadcast address

### Interface States

| Flag | Meaning |
|------|---------|
| `UP` | Administratively enabled |
| `LOWER_UP` | Physical carrier detected (cable/wireless connected) |
| `NO-CARRIER` | Cable unplugged / no wireless association |
| `DORMANT` | Waiting for protocol (e.g., 802.1X auth) |

### Bringing Interfaces Up/Down

```bash
# Bring interface down
sudo ip link set eth0 down

# Bring interface up
sudo ip link set eth0 up

# Rename an interface
sudo ip link set eth0 name wan0

# Change MTU (e.g., for jumbo frames)
sudo ip link set eth0 mtu 9000

# Change MAC address
sudo ip link set eth0 address 00:11:22:33:44:55
```

## ip addr: Layer 3 (IP Addresses)

`ip addr` manages **IP addresses** assigned to interfaces.

```bash
# Show all addresses
ip addr show
ip addr     # shorthand
ip a        # even shorter

# Show a specific interface
ip addr show eth0
ip addr show lo
```

### Reading ip addr output

```
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 ...
    link/ether 00:1a:2b:3c:4d:5e brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.100/24 brd 192.168.1.255 scope global dynamic eth0
       valid_lft 86342sec preferred_lft 86342sec
    inet6 fe80::21a:2bff:fe3c:4d5e/64 scope link
       valid_lft forever preferred_lft forever
```

- `inet 192.168.1.100/24` — IPv4 address with CIDR prefix
- `brd 192.168.1.255` — broadcast address
- `scope global` — address is globally routable
- `dynamic` — assigned by DHCP
- `inet6 fe80::...` — IPv6 link-local address (always present on UP interfaces)

### Adding and Removing Addresses

```bash
# Add an IPv4 address
sudo ip addr add 10.0.0.5/24 dev eth0

# Add with broadcast
sudo ip addr add 10.0.0.5/24 brd + dev eth0

# Add a secondary address
sudo ip addr add 10.0.0.6/24 dev eth0

# Remove an address
sudo ip addr del 10.0.0.5/24 dev eth0

# Remove all addresses from an interface
sudo ip addr flush dev eth0
```

## The Loopback Interface

```bash
ip addr show lo
# 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 ...
#     link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
#     inet 127.0.0.1/8 scope host lo
#     inet6 ::1/128 scope host
```

- `127.0.0.1` is the IPv4 loopback
- `::1` is the IPv6 loopback
- MTU 65536 — loopback doesn't have a physical limit

## ifconfig vs ip

```bash
# Legacy ifconfig equivalents
ifconfig                    → ip addr show
ifconfig eth0               → ip addr show eth0
ifconfig eth0 up            → ip link set eth0 up
ifconfig eth0 192.168.1.5   → ip addr add 192.168.1.5/24 dev eth0
```

## Practical Examples

```bash
# Find which interface has a specific IP
ip addr | grep "10\."

# Show only IPv4 addresses
ip -4 addr

# Show only IPv6 addresses
ip -6 addr

# Show interface stats (packet counts, errors)
ip -s link show eth0
```

## Further Reading

- [iproute2 command reference](https://baturin.org/docs/iproute2/) — Comprehensive annotated guide to every `ip addr` and `ip link` subcommand, including flags and real-world examples not covered by man pages.
- [ip(8) man page](https://man7.org/linux/man-pages/man8/ip.8.html) — The authoritative reference for the top-level `ip` command, covering all object types (link, addr, route, rule) and the JSON output format.
- [ip-link(8) man page](https://man7.org/linux/man-pages/man8/ip-link.8.html) — Documents every link type (`veth`, `vlan`, `bridge`, `vxlan`) and all interface flags (`UP`, `LOWER_UP`, `DORMANT`) explained in this lesson.
- [Arch Wiki: Network configuration](https://wiki.archlinux.org/title/Network_configuration) — Practical guide to configuring network interfaces on Linux using iproute2, covering static addresses, MTU, MAC addresses, and common troubleshooting steps.
- [Julia Evans networking zine](https://jvns.ca/networking-zine.pdf) — Visual illustrated guide to Linux networking concepts including interfaces, addresses, and routing — ideal for building intuition around the `ip` command output.
- [netdevice(7) man page](https://man7.org/linux/man-pages/man7/netdevice.7.html) — Documents the `ioctl` interface for network interface configuration that `ip link` uses internally, explaining the flags and state fields in `ip link show` output.
