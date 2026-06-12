#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: openssl is available (from block3/07)
check "openssl is available" \
  "command -v openssl > /dev/null 2>&1"

# Check 2: curl is available (from block2/03)
check "curl is available" \
  "command -v curl > /dev/null 2>&1"

# Check 3: openssl s_client can connect to a server
check "openssl s_client can connect to google.com:443" \
  "openssl s_client -connect google.com:443 -servername google.com </dev/null 2>/dev/null | grep -q 'CONNECTED'"

# Check 4: can negotiate TLS 1.3
check "TLS 1.3 can be negotiated with google.com" \
  "openssl s_client -connect google.com:443 -tls1_3 </dev/null 2>/dev/null | grep -q 'TLSv1.3'"

# Check 5: can negotiate TLS 1.2
check "TLS 1.2 can be requested" \
  "openssl s_client -connect google.com:443 -tls1_2 </dev/null 2>/dev/null | grep -qE 'TLSv1.2|Protocol'"

# Check 6: SNI is supported
check "openssl s_client supports -servername (SNI)" \
  "openssl s_client -connect google.com:443 -servername google.com </dev/null 2>/dev/null | grep -q CONNECTED"

# Check 7: ALPN flag is supported
check "openssl s_client supports -alpn flag" \
  "openssl s_client -connect google.com:443 -alpn 'h2,http/1.1' </dev/null 2>/dev/null | grep -q CONNECTED"

# Check 8: session resumption (save session)
check "openssl s_client -sess_out saves session" \
  "openssl s_client -connect google.com:443 -servername google.com \
   -sess_out /tmp/test_sess_$$.pem </dev/null > /dev/null 2>&1 && [ -f /tmp/test_sess_$$.pem ] && rm -f /tmp/test_sess_$$.pem"

# Check 9: curl supports HTTP/2
check "curl supports --http2 flag" \
  "curl --http2 -s -o /dev/null -w '%{http_version}' https://google.com 2>/dev/null | grep -q '2'"

# Check 10: tls_handshake practice directory exists
check "~/practice/tls_handshake directory exists" \
  "[ -d \$HOME/practice/tls_handshake ]"

# Check 11: tls_check.sh exists
check "tls_check.sh exists and is executable" \
  "[ -x \$HOME/practice/tls_handshake/tls_check.sh ]"

# Check 12: tls_check.sh uses openssl s_client
check "tls_check.sh uses openssl s_client" \
  "grep -q 's_client' \$HOME/practice/tls_handshake/tls_check.sh"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
