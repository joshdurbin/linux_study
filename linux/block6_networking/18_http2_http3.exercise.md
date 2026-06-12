# Exercise: HTTP/2 and HTTP/3

## Setup

```bash
mkdir -p ~/practice/http2
```

## Task 1: Check curl HTTP/2 Support

```bash
# See all features curl was compiled with
curl --version

# Check specifically for HTTP/2
curl --version | grep -i http2 && echo "HTTP/2 supported" || echo "HTTP/2 NOT supported"

# Check for HTTP/3
curl --version | grep -i http3 && echo "HTTP/3 supported" || echo "HTTP/3 not in this build"
```

## Task 2: Compare HTTP/1.1 vs HTTP/2 Responses

```bash
echo "=== HTTP/1.1 ==="
curl -sI --http1.1 https://google.com | head -3

echo ""
echo "=== HTTP/2 ==="
curl -sI --http2 https://google.com | head -3
```

The first line should show `HTTP/1.1 200` vs `HTTP/2 200`.

## Task 3: Observe ALPN Negotiation

```bash
# See h2 negotiated via ALPN (openssl from block3/07)
openssl s_client -connect google.com:443 \
    -alpn 'h2,http/1.1' </dev/null 2>&1 | grep -E "ALPN|protocol"

echo ""
echo "Requesting only HTTP/1.1:"
openssl s_client -connect google.com:443 \
    -alpn 'http/1.1' </dev/null 2>&1 | grep -E "ALPN|protocol"
```

## Task 4: Verbose HTTP/2 Session Details

```bash
# curl -v shows stream IDs and frame details for HTTP/2
curl -v --http2 -s -o /dev/null https://google.com 2>&1 \
    | grep -E "< HTTP/2|h2|stream|ALPN|Connected"
```

## Task 5: Check HTTP/3 Advertisement

```bash
# Does the server advertise HTTP/3 via the alt-svc header?
echo "Checking for HTTP/3 alt-svc advertisement:"
curl -sI --http2 https://cloudflare.com | grep -i "alt-svc"
curl -sI --http2 https://google.com | grep -i "alt-svc"

# alt-svc: h3=":443"; ma=86400  means HTTP/3 is available on UDP port 443
```

## Task 6: Measure Request Count Reduction

```bash
# HTTP/1.1 browsers open 6 TCP connections per host
# HTTP/2 uses 1. Check with ss.

# Start a curl download in background to hold a connection
curl -s --http2 https://google.com -o /dev/null --max-time 5 &

# How many connections to google?
sleep 1
ss -nt dst :443 2>/dev/null | head -10
wait
```

## Task 7: Write an HTTP Version Check Script

```bash
cat > ~/practice/http2/check_http_version.sh << 'EOF'
#!/bin/bash
# Usage: ./check_http_version.sh <host> [port]
HOST=${1:-google.com}
PORT=${2:-443}

echo "Checking $HOST:$PORT"

# Get HTTP version from response
VERSION=$(curl -sI --http2 --max-time 5 "https://$HOST:$PORT" 2>/dev/null | head -1 | awk '{print $1}')
echo "HTTP version: $VERSION"

# Check ALPN
ALPN=$(openssl s_client -connect "$HOST:$PORT" -alpn 'h2,http/1.1' \
    </dev/null 2>&1 | grep "ALPN protocol" | awk '{print $NF}')
echo "ALPN protocol: ${ALPN:-unknown}"

# Check for HTTP/3 alt-svc
ALTSVC=$(curl -sI --http2 --max-time 5 "https://$HOST" 2>/dev/null | grep -i "alt-svc" | grep h3)
if [ -n "$ALTSVC" ]; then
    echo "HTTP/3: advertised ($ALTSVC)"
else
    echo "HTTP/3: not advertised"
fi
EOF
chmod +x ~/practice/http2/check_http_version.sh
bash ~/practice/http2/check_http_version.sh google.com
```

## Expected Outcome

- `curl --version` shows HTTP/2 (and possibly HTTP/3) in features
- `curl -sI --http2 https://google.com` returns `HTTP/2 200`
- `curl -sI --http1.1 https://google.com` returns `HTTP/1.1 200`
- ALPN negotiation shows `h2` when HTTP/2 is requested
- Some servers show `alt-svc: h3=...` advertising HTTP/3
- `check_http_version.sh` reports protocol, ALPN, and HTTP/3 advertisement
