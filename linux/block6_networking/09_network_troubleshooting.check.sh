#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: ping is available
check "ping is available" \
  "command -v ping > /dev/null 2>&1"

# Check 2: loopback ping works
check "loopback ping (127.0.0.1) succeeds" \
  "ping -c 1 -W 2 127.0.0.1 > /dev/null 2>&1"

# Check 3: ip route is functional
check "ip route works" \
  "ip route > /dev/null 2>&1"

# Check 4: nc (netcat) is available
check "nc (netcat) is available" \
  "command -v nc > /dev/null 2>&1"

# Check 5: nc can test a local port
check "nc can connect to a local listener" \
  "nc -l -p 29876 & sleep 0.3; nc -zv -w 2 127.0.0.1 29876 > /dev/null 2>&1; RET=\$?; kill %1 2>/dev/null; [ \$RET -eq 0 ]"

# Check 6: practice directory exists
check "~/practice directory exists" \
  "[ -d \$HOME/practice ]"

# Check 7: network_check.sh exists
check "~/practice/network_check.sh exists" \
  "[ -f \$HOME/practice/network_check.sh ]"

# Check 8: network_check.sh is executable
check "network_check.sh is executable" \
  "[ -x \$HOME/practice/network_check.sh ]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
