# Network Packet Processing Performance

When a packet arrives at a NIC, it travels a long path through the kernel before reaching your application. Each stage is a potential bottleneck. This lesson covers that path, how to measure each stage, and how to tune it.

## The Packet Receive Path

```
NIC hardware
  └── DMA → ring buffer (in kernel memory)
        └── hardware interrupt (IRQ) → ksoftirqd or NET_RX softirq
              └── NAPI poll loop → netif_receive_skb
                    └── ip_rcv → tcp_rcv → socket receive buffer
                          └── application read()
```

The critical stages for tuning:
1. **Ring buffer** — NIC → kernel DMA
2. **IRQ handling** — which CPU processes the interrupt
3. **Softirq** — kernel's deferred interrupt processing
4. **Socket buffers** — kernel → application

## Ring Buffers

The NIC uses a ring buffer (circular queue) for incoming packets. If the kernel doesn't drain it fast enough, the NIC drops packets before they even enter the kernel.

```bash
# Check ring buffer size with ethtool (introduced in this lesson)
ethtool -g eth0
# Pre-set maximums:
#   RX:  4096
#   TX:  4096
# Current hardware settings:
#   RX:  256
#   TX:  256

# Increase the ring buffer size
sudo ethtool -G eth0 rx 4096 tx 4096
```

### Checking for Ring Buffer Drops

```bash
ethtool -S eth0 | grep -i "drop\|miss\|error"
# rx_missed_errors: 12345   ← ring buffer overflow drops
# rx_no_buffer_count: 0
```

## IRQ Affinity — Which CPU Handles Interrupts

By default, the kernel assigns NIC interrupts to one or a few CPUs. High traffic from a single NIC can saturate that CPU while others are idle.

```bash
# See IRQ numbers for network interfaces
cat /proc/interrupts | grep eth0
# Or for modern NICs with multiple queues:
cat /proc/interrupts | grep -E "eth0|ens|enp"

# Check current affinity (bitmask of CPUs)
IRQ_NUM=42
cat /proc/irq/$IRQ_NUM/smp_affinity      # hex bitmask
cat /proc/irq/$IRQ_NUM/smp_affinity_list # human-readable: 0-3

# Set affinity to CPU 2 only (bit 2 = 0x4)
echo 4 | sudo tee /proc/irq/$IRQ_NUM/smp_affinity

# Set affinity to CPUs 0 and 1 (bits 0+1 = 0x3)
echo 3 | sudo tee /proc/irq/$IRQ_NUM/smp_affinity
```

For NICs with multiple hardware queues (common on 10G+ cards), each queue has its own IRQ. The goal is to spread them across CPUs evenly.

## Softirq — /proc/net/softnet_stat

The kernel defers most packet processing from hardware interrupts to softirqs (software interrupts), handled by the `NET_RX_SOFTIRQ` mechanism. `/proc/net/softnet_stat` shows per-CPU softirq stats.

```bash
cat /proc/net/softnet_stat
# One line per CPU, hex values:
# total  dropped  time_squeeze  0 0 0 0 0 0 cpu_collision throttled

# More readable with awk:
awk '
NR==1 { print "CPU  total       dropped     squeezed" }
{
    cpu = NR-1
    printf "%-4d 0x%-10s 0x%-10s 0x%s\n", cpu, $1, $2, $3
}
' /proc/net/softnet_stat
```

Key columns (all hex):

| Column | Meaning |
|--------|---------|
| `total` | Total frames received by this CPU's softirq |
| `dropped` | Frames dropped because the backlog queue was full |
| `time_squeeze` | Softirq budget exhausted before backlog was empty — had to reschedule |

**Non-zero `dropped`**: the kernel's per-CPU `netdev_max_backlog` queue overflowed. Tune with:
```bash
sysctl net.core.netdev_max_backlog        # default: 1000
sudo sysctl -w net.core.netdev_max_backlog=10000
```

**Non-zero `time_squeeze`**: the softirq ran out of its `netdev_budget` before draining all packets. Tune with:
```bash
sysctl net.core.netdev_budget             # default: 300 packets per softirq run
sudo sysctl -w net.core.netdev_budget=600
```

## RPS — Receive Packet Steering

By default, all packets from a NIC queue are processed on one CPU. **RPS** (Receive Packet Steering) is a software mechanism that distributes packet processing across multiple CPUs based on a hash of the flow.

```bash
# Check current RPS configuration for eth0, queue 0
cat /sys/class/net/eth0/queues/rx-0/rps_cpus   # hex bitmask, 0 = disabled

# Enable RPS on all CPUs (e.g., 4-CPU system: 0xf = CPUs 0-3)
echo f | sudo tee /sys/class/net/eth0/queues/rx-0/rps_cpus

# Set RPS flow table size (larger = better per-flow locality)
echo 4096 | sudo tee /sys/class/net/eth0/queues/rx-0/rps_flow_cnt
```

RPS is useful when the NIC has only one hardware queue (common on VMs and older cards). For NICs with multiple hardware queues, spread the IRQs instead.

## RFS — Receive Flow Steering

**RFS** (Receive Flow Steering) extends RPS by sending packets to the CPU that is actually running the application consuming them — improving cache locality.

```bash
# Enable RFS globally
sudo sysctl -w net.core.rps_sock_flow_entries=32768

# Enable RFS per queue
echo 32768 | sudo tee /sys/class/net/eth0/queues/rx-0/rps_flow_cnt
```

## ethtool — NIC Statistics and Settings

`ethtool` is the primary tool for NIC configuration and diagnostics.

```bash
# NIC basic info and link speed
ethtool eth0

# Driver and hardware info
ethtool -i eth0

# NIC statistics (driver-specific, very detailed)
ethtool -S eth0

# Interrupt coalescing (batching interrupts reduces CPU overhead)
ethtool -c eth0
# rx-usecs: 50   ← generate IRQ after 50µs of no new packets (or full frame count)

# Tune interrupt coalescing: fewer IRQs, higher latency, lower CPU
sudo ethtool -C eth0 rx-usecs 100

# NIC offloads (features the NIC handles in hardware)
ethtool -k eth0
# tx-checksumming: on
# generic-segmentation-offload: on
# large-receive-offload: off
```

## Putting It Together: Diagnosing Packet Drop

```bash
# 1. Check if packets are being dropped at the NIC ring buffer
ethtool -S eth0 | grep -i drop

# 2. Check if softirq backlog is dropping packets
awk 'NR>1 {if (substr($2,1) != "00000000") print "CPU"NR-2" dropping: "$2}' \
    /proc/net/softnet_stat

# 3. Check if the socket's receive buffer is overflowing
# ss was introduced in block6 — use it here:
ss -unm    # UDP socket stats including receive buffer overflows

# 4. Check system-wide socket drop counters
cat /proc/net/snmp | grep -E "^Udp:|^UdpLite:"
# Udp: InDatagrams ... RcvbufErrors ... — RcvbufErrors are app-layer drops
```

## Tuning Reference

| Bottleneck | Symptom | Tuning |
|------------|---------|--------|
| NIC ring buffer | `rx_missed_errors` in ethtool -S | `ethtool -G eth0 rx 4096` |
| Softirq backlog | `dropped` in /proc/net/softnet_stat | `sysctl net.core.netdev_max_backlog=10000` |
| Softirq budget | `time_squeeze` in /proc/net/softnet_stat | `sysctl net.core.netdev_budget=600` |
| Single-CPU IRQ | one CPU at 100% `si` in top | IRQ affinity or RPS |
| App buffer overflow | `RcvbufErrors` in /proc/net/snmp | `sysctl net.core.rmem_max` |

## Further Reading

- [Brendan Gregg: Linux network performance](https://www.brendangregg.com/linuxperf.html#Network) — The network section of Brendan Gregg's Linux performance page, with the tool map covering the full receive path from ring buffer through softirq to socket buffer.
- [kernel.org: Scaling in the Linux networking stack](https://www.kernel.org/doc/html/latest/networking/scaling.html) — The definitive kernel documentation for RSS, RPS, RFS, XPS, and interrupt coalescing — every tuning mechanism described in this lesson with implementation details.
- [Cloudflare blog: How we built the Cloudflare edge](https://blog.cloudflare.com/how-we-built-cloudflare-edge/) — Real-world experience tuning the Linux network stack at millions of packets per second, covering ring buffers, IRQ affinity, RPS, and `netdev_max_backlog`.
- [ethtool(8) man page](https://man7.org/linux/man-pages/man8/ethtool.8.html) — Complete reference for `ethtool -g` (ring buffer), `ethtool -S` (NIC statistics), `ethtool -c` (interrupt coalescing), and `ethtool -k` (offload features) used in the diagnostic section.
