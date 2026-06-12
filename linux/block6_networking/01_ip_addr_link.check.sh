#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: ip command is available
check "ip command is available" \
  "command -v ip > /dev/null 2>&1"

# Check 2: ip addr show runs without error
check "ip addr show runs successfully" \
  "ip addr show > /dev/null 2>&1"

# Check 3: loopback interface exists
check "loopback interface (lo) exists" \
  "ip link show lo > /dev/null 2>&1"

# Check 4: loopback has 127.0.0.1
check "loopback has 127.0.0.1 address" \
  "ip addr show lo | grep -q '127.0.0.1'"

# Check 5: practice directory exists
check "~/practice directory exists" \
  "[ -d \$HOME/practice ]"

# Check 6: interfaces.txt exists
check "~/practice/interfaces.txt exists" \
  "[ -f \$HOME/practice/interfaces.txt ]"

# Check 7: interfaces.txt is not empty
check "interfaces.txt is not empty" \
  "[ -s \$HOME/practice/interfaces.txt ]"

# Check 8: interfaces.txt contains at least one interface entry
check "interfaces.txt contains interface information" \
  "grep -qE '(inet|link/ether|mtu|UP)' \$HOME/practice/interfaces.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
