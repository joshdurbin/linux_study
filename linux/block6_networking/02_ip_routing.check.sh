#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: ip command is available
check "ip command is available" \
  "command -v ip > /dev/null 2>&1"

# Check 2: ip route runs successfully
check "ip route runs without error" \
  "ip route > /dev/null 2>&1"

# Check 3: ip rule runs successfully
check "ip rule show runs without error" \
  "ip rule show > /dev/null 2>&1"

# Check 4: routing table has at least one entry
check "routing table has at least one route" \
  "[ \$(ip route | wc -l) -ge 1 ]"

# Check 5: ip route get works for loopback
check "ip route get 127.0.0.1 works" \
  "ip route get 127.0.0.1 > /dev/null 2>&1"

# Check 6: practice directory exists
check "~/practice directory exists" \
  "[ -d \$HOME/practice ]"

# Check 7: routing_notes.txt exists
check "~/practice/routing_notes.txt exists" \
  "[ -f \$HOME/practice/routing_notes.txt ]"

# Check 8: routing_notes.txt contains routing info
check "routing_notes.txt contains routing data" \
  "grep -qE '(dev|via|scope|proto)' \$HOME/practice/routing_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
