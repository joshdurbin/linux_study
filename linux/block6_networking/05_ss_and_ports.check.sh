#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: ss command is available
check "ss command is available" \
  "command -v ss > /dev/null 2>&1"

# Check 2: ss -tlnp runs successfully
check "ss -tlnp runs without error" \
  "ss -tlnp > /dev/null 2>&1"

# Check 3: ss -s (summary) runs successfully
check "ss -s summary runs without error" \
  "ss -s > /dev/null 2>&1"

# Check 4: loopback has a listening socket (lo socket exists)
check "ss can show Unix sockets" \
  "ss -xlnp > /dev/null 2>&1"

# Check 5: practice directory exists
check "~/practice directory exists" \
  "[ -d \$HOME/practice ]"

# Check 6: ports.txt exists
check "~/practice/ports.txt exists" \
  "[ -f \$HOME/practice/ports.txt ]"

# Check 7: ports.txt contains LISTEN
check "ports.txt contains LISTEN" \
  "grep -q 'LISTEN' \$HOME/practice/ports.txt"

# Check 8: ports.txt is non-empty
check "ports.txt is not empty" \
  "[ -s \$HOME/practice/ports.txt ]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
