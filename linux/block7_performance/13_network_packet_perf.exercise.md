# Exercise: Network Packet Processing Performance

## Setup

```bash
mkdir -p ~/practice/netperf
```

## Task 1: Identify the Network Interface

```bash
# List interfaces (introduced in block6)
ip link show

# Pick the primary interface (often eth0, ens3, or similar)
# For the rest of this exercise, substitute your interface name for ETH
ETH=$(ip route | awk '/^default/ {print $5; exit}')
echo "Primary interface: $ETH"
```

## Task 2: Ring Buffer — Check Size and Drops

```bash
ETH=$(ip route | awk '/^default/ {print $5; exit}')

# Show current and maximum ring buffer sizes
ethtool -g $ETH 2>/dev/null || echo "ethtool -g not supported for $ETH (common in containers)"

# Check for NIC-level drop counters
ethtool -S $ETH 2>/dev/null | grep -iE "drop|miss|error" | head -20 \
    || echo "ethtool -S not supported (may need physical NIC or host access)"
```

Note: In Docker containers, `ethtool` commands that require hardware access may return limited info.

## Task 3: Read /proc/net/softnet_stat

```bash
echo "=== softnet_stat (per-CPU packet stats) ==="
awk '
BEGIN { print "CPU  total       dropped     time_squeeze" }
{
    printf "%-4d 0x%-10s 0x%-10s 0x%s\n", NR-1, $1, $2, $3
}
' /proc/net/softnet_stat

# Check for any dropped packets (column 2 non-zero)
drops=$(awk '{val=strtonum("0x"$2); if (val>0) total+=val} END {print total+0}' /proc/net/softnet_stat)
echo ""
echo "Total softirq drops across all CPUs: $drops"

# Check for time_squeeze (column 3 non-zero)
squeeze=$(awk '{val=strtonum("0x"$3); if (val>0) total+=val} END {print total+0}' /proc/net/softnet_stat)
echo "Total time_squeeze events: $squeeze"
```

## Task 4: Softirq Settings

```bash
# Current backlog queue size
echo "netdev_max_backlog: $(cat /proc/sys/net/core/netdev_max_backlog)"

# Current softirq budget
echo "netdev_budget: $(cat /proc/sys/net/core/netdev_budget)"
```

## Task 5: Check RPS Configuration

```bash
ETH=$(ip route | awk '/^default/ {print $5; exit}')

# List RX queues for the interface
ls /sys/class/net/$ETH/queues/ 2>/dev/null | grep rx

# Check RPS config for queue 0
if [ -f /sys/class/net/$ETH/queues/rx-0/rps_cpus ]; then
    echo "RPS cpus (rx-0): $(cat /sys/class/net/$ETH/queues/rx-0/rps_cpus)"
    # 00000000 = RPS disabled
    # ffffffff = all CPUs
else
    echo "RPS configuration not accessible (normal in containers)"
fi
```

## Task 6: Check Socket Drop Counters

```bash
# UDP socket stats using ss (from block6)
ss -s    # summary including drops

# System-wide protocol stats from /proc/net/snmp
echo ""
echo "=== UDP stats ==="
awk '/^Udp:/ {
    if (NR % 2 == 1) { for (i=1;i<=NF;i++) header[i]=$i }
    else { for (i=1;i<=NF;i++) print header[i]": "$i }
}' /proc/net/snmp | grep -E "InDatagrams|RcvbufErrors|InErrors"
```

`RcvbufErrors` = packets dropped because the application's socket receive buffer was full.

## Task 7: Write a Network Health Check Script

```bash
cat > ~/practice/netperf/net_health.sh << 'EOF'
#!/bin/bash
ETH=$(ip route | awk '/^default/ {print $5; exit}')
echo "Interface: $ETH"

# softirq drops
DROPS=$(awk '{val=strtonum("0x"$2); total+=val} END {print total+0}' /proc/net/softnet_stat)
echo "Softirq drops (total): $DROPS"

# softirq squeeze
SQUEEZE=$(awk '{val=strtonum("0x"$3); total+=val} END {print total+0}' /proc/net/softnet_stat)
echo "Time_squeeze events (total): $SQUEEZE"

# backlog setting
echo "netdev_max_backlog: $(cat /proc/sys/net/core/netdev_max_backlog)"
echo "netdev_budget: $(cat /proc/sys/net/core/netdev_budget)"

# UDP receive buffer errors
RCVBUF=$(awk '/^Udp:/ && /[0-9]/ {
    split($0, a); for (i=1;i<=length(a);i++) if (a[i]~/^[0-9]+$/) print a[i]
}' /proc/net/snmp | awk 'NR==6')
echo "UDP RcvbufErrors: ${RCVBUF:-unknown}"
EOF
chmod +x ~/practice/netperf/net_health.sh
bash ~/practice/netperf/net_health.sh
```

## Expected Outcome

- `ethtool` is installed and shows ring buffer info (on physical NICs)
- `/proc/net/softnet_stat` is readable and parseable with `awk`
- `dropped` and `time_squeeze` columns are extracted and summed
- `/proc/sys/net/core/netdev_max_backlog` and `netdev_budget` are readable
- `/proc/net/snmp` UDP stats are readable
- `~/practice/netperf/net_health.sh` reads softirq stats and sysctl values
