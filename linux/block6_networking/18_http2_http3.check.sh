#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: curl is available (from block2/03)
check "curl is available" \
  "command -v curl > /dev/null 2>&1"

# Check 2: curl has HTTP/2 support
check "curl was compiled with HTTP/2 support" \
  "curl --version 2>/dev/null | grep -qi 'http2\|nghttp2'"

# Check 3: curl --http2 flag works
check "curl --http2 flag is accepted" \
  "curl --http2 -s -o /dev/null -w '%{http_version}' https://google.com 2>/dev/null | grep -qE '^2'"

# Check 4: HTTP/1.1 can be forced
check "curl --http1.1 returns HTTP/1.1 response" \
  "curl --http1.1 -sI https://google.com 2>/dev/null | head -1 | grep -q 'HTTP/1.1'"

# Check 5: HTTP/2 response shows version 2
check "HTTP/2 request to google returns HTTP/2 response" \
  "curl -sI --http2 https://google.com 2>/dev/null | head -1 | grep -q 'HTTP/2'"

# Check 6: openssl s_client is available (from block3/07)
check "openssl s_client is available" \
  "command -v openssl > /dev/null 2>&1"

# Check 7: ALPN negotiation works
check "openssl s_client -alpn negotiates h2 with google.com" \
  "openssl s_client -connect google.com:443 -alpn 'h2,http/1.1' </dev/null 2>/dev/null | grep -q 'CONNECTED'"

# Check 8: practice/http2 directory exists
check "~/practice/http2 directory exists" \
  "[ -d \$HOME/practice/http2 ]"

# Check 9: check_http_version.sh exists and is executable
check "check_http_version.sh exists and is executable" \
  "[ -x \$HOME/practice/http2/check_http_version.sh ]"

# Check 10: check_http_version.sh uses curl --http2
check "check_http_version.sh uses curl --http2" \
  "grep -q 'http2' \$HOME/practice/http2/check_http_version.sh"

# Check 11: check_http_version.sh uses openssl for ALPN
check "check_http_version.sh checks ALPN" \
  "grep -q 'alpn\|ALPN' \$HOME/practice/http2/check_http_version.sh"

# Check 12: alt-svc header is checked
check "check_http_version.sh checks for alt-svc/HTTP3 advertisement" \
  "grep -q 'alt-svc\|h3' \$HOME/practice/http2/check_http_version.sh"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
