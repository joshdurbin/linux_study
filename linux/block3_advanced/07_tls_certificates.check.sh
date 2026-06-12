#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: openssl is available
check "openssl is available" \
  "command -v openssl > /dev/null 2>&1"

# Check 2: tls practice directory exists
check "~/practice/tls directory exists" \
  "[ -d \$HOME/practice/tls ]"

# Check 3: CA key exists
check "ca.key exists" \
  "[ -f \$HOME/practice/tls/ca.key ]"

# Check 4: CA cert exists
check "ca.crt exists" \
  "[ -f \$HOME/practice/tls/ca.crt ]"

# Check 5: CA cert is self-signed (issuer == subject)
check "ca.crt is self-signed" \
  "openssl x509 -in \$HOME/practice/tls/ca.crt -noout -subject -issuer 2>/dev/null | awk -F= 'NR==1{s=\$2} NR==2{i=\$2} END{exit (s==i)?0:1}'"

# Check 6: server key exists
check "server.key exists" \
  "[ -f \$HOME/practice/tls/server.key ]"

# Check 7: server cert exists
check "server.crt exists" \
  "[ -f \$HOME/practice/tls/server.crt ]"

# Check 8: server cert verifies against CA
check "server.crt verifies against ca.crt" \
  "openssl verify -CAfile \$HOME/practice/tls/ca.crt \$HOME/practice/tls/server.crt > /dev/null 2>&1"

# Check 9: server cert is not expired
check "server.crt is currently valid" \
  "openssl x509 -in \$HOME/practice/tls/server.crt -checkend 0 > /dev/null 2>&1"

# Check 10: server cert and key match (same public key)
check "server.crt and server.key match" \
  "diff <(openssl x509 -in \$HOME/practice/tls/server.crt -pubkey -noout 2>/dev/null) \
        <(openssl rsa -in \$HOME/practice/tls/server.key -pubout 2>/dev/null) > /dev/null 2>&1"

# Check 11: client cert exists
check "client.crt exists" \
  "[ -f \$HOME/practice/tls/client.crt ]"

# Check 12: client cert verifies against CA
check "client.crt verifies against ca.crt" \
  "openssl verify -CAfile \$HOME/practice/tls/ca.crt \$HOME/practice/tls/client.crt > /dev/null 2>&1"

# Check 13: check_cert.sh exists and is executable
check "check_cert.sh exists and is executable" \
  "[ -x \$HOME/practice/tls/check_cert.sh ]"

# Check 14: check_cert.sh uses openssl checkend
check "check_cert.sh uses openssl checkend" \
  "grep -q 'checkend' \$HOME/practice/tls/check_cert.sh"

# Check 15: openssl can connect to a remote server (network check)
check "openssl s_client can connect to example.com:443" \
  "openssl s_client -connect example.com:443 -servername example.com </dev/null 2>/dev/null | grep -q 'CONNECTED'"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
