#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: ethtool is available
check "ethtool is available" \
  "command -v ethtool > /dev/null 2>&1"

# Check 2: /proc/net/softnet_stat is readable
check "/proc/net/softnet_stat is readable" \
  "[ -r /proc/net/softnet_stat ] && [ \"\$(wc -l < /proc/net/softnet_stat)\" -ge 1 ]"

# Check 3: softnet_stat has one line per CPU
check "/proc/net/softnet_stat has one line per logical CPU" \
  "[ \"\$(wc -l < /proc/net/softnet_stat | tr -d ' ')\" -eq \"\$(nproc)\" ]"

# Check 4: softnet_stat columns are parseable (first column is hex)
check "softnet_stat first column is a hex string" \
  "awk 'NR==1 {exit (\$1 ~ /^[0-9a-f]+\$/) ? 0 : 1}' /proc/net/softnet_stat"

# Check 5: netdev_max_backlog sysctl is readable
check "net.core.netdev_max_backlog is readable" \
  "[ -r /proc/sys/net/core/netdev_max_backlog ] && grep -q '[0-9]' /proc/sys/net/core/netdev_max_backlog"

# Check 6: netdev_budget sysctl is readable
check "net.core.netdev_budget is readable" \
  "[ -r /proc/sys/net/core/netdev_budget ] && grep -q '[0-9]' /proc/sys/net/core/netdev_budget"

# Check 7: /proc/net/snmp is readable and has UDP section
check "/proc/net/snmp is readable and has Udp section" \
  "[ -r /proc/net/snmp ] && grep -q '^Udp:' /proc/net/snmp"

# Check 8: ss is available (from block6)
check "ss is available" \
  "command -v ss > /dev/null 2>&1"

# Check 9: ip route works to identify default interface (from block6)
check "ip route can identify the default interface" \
  "ip route 2>/dev/null | grep -q '^default'"

# Check 10: /sys/class/net directory is accessible
check "/sys/class/net lists network interfaces" \
  "ls /sys/class/net/ > /dev/null 2>&1"

# Check 11: practice/netperf directory exists
check "~/practice/netperf directory exists" \
  "[ -d \$HOME/practice/netperf ]"

# Check 12: net_health.sh exists
check "net_health.sh exists" \
  "[ -f \$HOME/practice/netperf/net_health.sh ]"

# Check 13: net_health.sh references softnet_stat
check "net_health.sh reads /proc/net/softnet_stat" \
  "grep -q 'softnet_stat' \$HOME/practice/netperf/net_health.sh"

# Check 14: net_health.sh reads netdev sysctl
check "net_health.sh reads netdev_max_backlog or netdev_budget" \
  "grep -qE 'netdev_max_backlog|netdev_budget' \$HOME/practice/netperf/net_health.sh"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
