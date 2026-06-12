#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: iptables is available
check "iptables is available" \
  "command -v iptables > /dev/null 2>&1"

# Check 2: iptables -L runs without error
check "iptables -L runs successfully" \
  "sudo iptables -L -n > /dev/null 2>&1"

# Check 3: ufw or nft is available
check "ufw or nft is available" \
  "command -v ufw > /dev/null 2>&1 || command -v nft > /dev/null 2>&1"

# Check 4: iptables has filter table with INPUT chain
check "iptables filter table has INPUT chain" \
  "sudo iptables -L INPUT -n > /dev/null 2>&1"

# Check 5: practice directory exists
check "~/practice directory exists" \
  "[ -d \$HOME/practice ]"

# Check 6: firewall_notes.txt exists
check "~/practice/firewall_notes.txt exists" \
  "[ -f \$HOME/practice/firewall_notes.txt ]"

# Check 7: firewall_notes.txt contains firewall content
check "firewall_notes.txt contains firewall information" \
  "grep -qiE '(iptables|ufw|nftables|nft|ACCEPT|DROP|INPUT|firewall)' \$HOME/practice/firewall_notes.txt"

# Check 8: firewall_notes.txt is non-empty
check "firewall_notes.txt is not empty" \
  "[ -s \$HOME/practice/firewall_notes.txt ]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
