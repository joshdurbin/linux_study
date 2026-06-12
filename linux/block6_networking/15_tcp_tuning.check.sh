#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: sysctl is available
check "sysctl is available" \
  "command -v sysctl > /dev/null 2>&1"

# Check 2: TCP congestion control parameter is readable
check "net.ipv4.tcp_congestion_control is readable" \
  "sysctl -n net.ipv4.tcp_congestion_control > /dev/null 2>&1"

# Check 3: available congestion control algorithms list
check "net.ipv4.tcp_available_congestion_control lists at least one algorithm" \
  "sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null | grep -qE 'cubic|reno|bbr'"

# Check 4: TCP buffer parameters readable
check "net.ipv4.tcp_rmem is readable" \
  "sysctl -n net.ipv4.tcp_rmem > /dev/null 2>&1"

check "net.ipv4.tcp_wmem is readable" \
  "sysctl -n net.ipv4.tcp_wmem > /dev/null 2>&1"

# Check 6: keepalive parameters readable
check "tcp_keepalive_time is readable" \
  "[ \"\$(sysctl -n net.ipv4.tcp_keepalive_time 2>/dev/null)\" -gt 0 ]"

check "tcp_keepalive_intvl is readable" \
  "[ \"\$(sysctl -n net.ipv4.tcp_keepalive_intvl 2>/dev/null)\" -gt 0 ]"

check "tcp_keepalive_probes is readable" \
  "[ \"\$(sysctl -n net.ipv4.tcp_keepalive_probes 2>/dev/null)\" -gt 0 ]"

# Check 9: keepalive_time was tuned to 60
check "tcp_keepalive_time is tuned to 60" \
  "[ \"\$(sysctl -n net.ipv4.tcp_keepalive_time 2>/dev/null)\" -eq 60 ]"

# Check 10: TIME_WAIT reuse parameter readable
check "tcp_tw_reuse is readable" \
  "sysctl -n net.ipv4.tcp_tw_reuse > /dev/null 2>&1"

# Check 11: ephemeral port range readable
check "ip_local_port_range is readable" \
  "sysctl -n net.ipv4.ip_local_port_range > /dev/null 2>&1"

# Check 12: somaxconn readable
check "net.core.somaxconn is readable" \
  "[ \"\$(sysctl -n net.core.somaxconn 2>/dev/null)\" -gt 0 ]"

# Check 13: ss can show socket states
check "ss shows socket state distribution" \
  "ss -ant | awk 'NR>1 {count++} END {exit (count>=0)?0:1}'"

# Check 14: practice directory exists
check "~/practice/tcp_tuning directory exists" \
  "[ -d \$HOME/practice/tcp_tuning ]"

# Check 15: tcp_summary.sh exists and references sysctl
check "tcp_summary.sh exists and uses sysctl" \
  "[ -f \$HOME/practice/tcp_tuning/tcp_summary.sh ] && grep -q 'sysctl' \$HOME/practice/tcp_tuning/tcp_summary.sh"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
