# Exercise: IP Routing

## Setup

```bash
mkdir -p ~/practice
```

## Task 1: Display the Routing Table

```bash
ip route show
```

Identify:
1. The default route — what is the gateway IP?
2. The directly connected subnet route — what network are you on?
3. Any other routes present

```bash
# Just the default route
ip route show default
```

## Task 2: Understand Each Route Field

Look at the main routing table:

```bash
ip route
```

For the default route, identify:
- Gateway IP (`via X.X.X.X`)
- Outgoing interface (`dev ethX`)
- Protocol (`proto dhcp` or `proto static`)
- Metric (lower = preferred)

## Task 3: Use ip route get to Simulate Lookups

```bash
# Where would traffic to 8.8.8.8 go?
ip route get 8.8.8.8

# Where would traffic to your own IP go?
MY_IP=$(ip -4 addr show | grep -oP '(?<=inet )\d+\.\d+\.\d+\.\d+' | grep -v 127 | head -1)
echo "My IP: $MY_IP"
ip route get $MY_IP 2>/dev/null || ip route get 127.0.0.1

# Where would loopback traffic go?
ip route get 127.0.0.1
```

## Task 4: Check Routing Policy Rules

```bash
ip rule show
```

You should see at least three rules (local, main, default tables).

## Task 5: Check IP Forwarding Status

```bash
cat /proc/sys/net/ipv4/ip_forward
sysctl net.ipv4.ip_forward
```

A value of `0` is expected on a normal workstation/container.

## Task 6: Save Routing Information

```bash
echo "=== Routing Table $(date) ===" > ~/practice/routing_notes.txt
echo "" >> ~/practice/routing_notes.txt
echo "--- ip route ---" >> ~/practice/routing_notes.txt
ip route >> ~/practice/routing_notes.txt
echo "" >> ~/practice/routing_notes.txt
echo "--- ip rule ---" >> ~/practice/routing_notes.txt
ip rule show >> ~/practice/routing_notes.txt
echo "" >> ~/practice/routing_notes.txt
echo "--- ip_forward ---" >> ~/practice/routing_notes.txt
echo "net.ipv4.ip_forward = $(cat /proc/sys/net/ipv4/ip_forward)" >> ~/practice/routing_notes.txt

cat ~/practice/routing_notes.txt
```

## Task 7: Understand the Local Routing Table

```bash
# The local table handles traffic destined for the machine itself
ip route show table local
```

You'll see entries for loopback and local interface addresses.

## Expected Outcome

- `~/practice/routing_notes.txt` exists with routing table content
- You can interpret ip route output and identify default gateway
- You understand how `ip route get` simulates packet forwarding decisions
