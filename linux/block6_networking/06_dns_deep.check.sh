#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: dig is installed
check "dig is installed" \
  "command -v dig > /dev/null 2>&1"

# Check 2: /etc/resolv.conf exists
check "/etc/resolv.conf exists" \
  "[ -f /etc/resolv.conf ]"

# Check 3: /etc/nsswitch.conf exists and has hosts line
check "/etc/nsswitch.conf has hosts entry" \
  "grep -q '^hosts' /etc/nsswitch.conf"

# Check 4: /etc/hosts has localhost
check "/etc/hosts has localhost entry" \
  "grep -q localhost /etc/hosts"

# Check 5: dig can resolve localhost
check "dig can resolve localhost" \
  "dig localhost +short > /dev/null 2>&1"

# Check 6: practice directory exists
check "~/practice directory exists" \
  "[ -d \$HOME/practice ]"

# Check 7: dns_notes.txt exists
check "~/practice/dns_notes.txt exists" \
  "[ -f \$HOME/practice/dns_notes.txt ]"

# Check 8: dns_notes.txt contains DNS content
check "dns_notes.txt contains DNS information" \
  "grep -qiE '(nameserver|resolv|dig|record|TTL|CNAME|MX)' \$HOME/practice/dns_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
