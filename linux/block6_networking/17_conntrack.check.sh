#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: conntrack tool is available
check "conntrack tool is available" \
  "command -v conntrack > /dev/null 2>&1"

# Check 2: netfilter sysctl namespace is accessible
check "net.netfilter sysctl namespace is accessible" \
  "sysctl -a 2>/dev/null | grep -q 'net.netfilter' || [ -d /proc/sys/net/netfilter ]"

# Check 3: nf_conntrack_max is readable
check "nf_conntrack_max is readable" \
  "sysctl -n net.netfilter.nf_conntrack_max > /dev/null 2>&1 || \
   [ -r /proc/sys/net/netfilter/nf_conntrack_max ]"

# Check 4: nf_conntrack_count is readable
check "nf_conntrack_count is readable" \
  "sysctl -n net.netfilter.nf_conntrack_count > /dev/null 2>&1 || \
   [ -r /proc/sys/net/netfilter/nf_conntrack_count ]"

# Check 5: conntrack can list (even if empty)
check "conntrack -L runs without fatal error" \
  "sudo conntrack -L > /dev/null 2>&1; [ \$? -ne 127 ]"

# Check 6: /proc/net/nf_conntrack exists
check "/proc/net/nf_conntrack is accessible" \
  "sudo cat /proc/net/nf_conntrack > /dev/null 2>&1 || sudo conntrack -L > /dev/null 2>&1"

# Check 7: TCP timeout parameters are readable
check "nf_conntrack_tcp_timeout_established is readable" \
  "sysctl -n net.netfilter.nf_conntrack_tcp_timeout_established > /dev/null 2>&1"

# Check 8: UDP timeout is readable
check "nf_conntrack_udp_timeout is readable" \
  "sysctl -n net.netfilter.nf_conntrack_udp_timeout > /dev/null 2>&1"

# Check 9: practice/conntrack directory exists
check "~/practice/conntrack directory exists" \
  "[ -d \$HOME/practice/conntrack ]"

# Check 10: ct_health.sh exists
check "ct_health.sh exists" \
  "[ -f \$HOME/practice/conntrack/ct_health.sh ]"

# Check 11: ct_health.sh references conntrack parameters
check "ct_health.sh references nf_conntrack" \
  "grep -q 'nf_conntrack' \$HOME/practice/conntrack/ct_health.sh"

# Check 12: ct_health.sh runs without crash
check "ct_health.sh executes successfully" \
  "bash \$HOME/practice/conntrack/ct_health.sh > /dev/null 2>&1"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
