# Exercise: TLS Handshake Internals

## Setup

```bash
mkdir -p ~/practice/tls_handshake
```

## Task 1: Observe a Full TLS Handshake

```bash
# Connect to a real server and capture handshake details
openssl s_client -connect google.com:443 -servername google.com </dev/null 2>&1 \
    | grep -E "Protocol|Cipher|Session-ID|TLS session ticket|Verify return"
```

## Task 2: Compare TLS 1.2 and TLS 1.3

```bash
echo "=== TLS 1.2 ==="
openssl s_client -connect google.com:443 -tls1_2 </dev/null 2>&1 \
    | grep -E "Protocol|Cipher"

echo ""
echo "=== TLS 1.3 ==="
openssl s_client -connect google.com:443 -tls1_3 </dev/null 2>&1 \
    | grep -E "Protocol|Cipher"
```

Note the different cipher suite format: TLS 1.3 uses `TLS_AES_256_GCM_SHA384`; TLS 1.2 uses `ECDHE-RSA-AES256-GCM-SHA384`.

## Task 3: Inspect the Certificate Chain

```bash
# Show all certs in the chain (leaf + intermediates)
openssl s_client -connect google.com:443 -showcerts </dev/null 2>&1 \
    | grep -E "^subject|^issuer|s:|i:" | head -20
```

## Task 4: SNI — Same IP, Different Certificates

```bash
# Get the cert for two different hostnames on the same Cloudflare IP range
# (Both google.com and example.com are served on shared infrastructure)
echo "=== Without SNI (sends no hostname) ==="
openssl s_client -connect google.com:443 </dev/null 2>/dev/null \
    | openssl x509 -noout -subject 2>/dev/null

echo ""
echo "=== With SNI (explicit hostname) ==="
openssl s_client -connect google.com:443 -servername google.com </dev/null 2>/dev/null \
    | openssl x509 -noout -subject 2>/dev/null
```

## Task 5: ALPN Protocol Negotiation

```bash
# Does this server offer h2 (HTTP/2)?
openssl s_client -connect google.com:443 \
    -alpn 'h2,http/1.1' </dev/null 2>&1 | grep -E "ALPN|protocol"

# Compare: curl shows the negotiated protocol
curl -v --http2 -s -o /dev/null https://google.com 2>&1 \
    | grep -E "ALPN|h2|HTTP/[12]"
```

## Task 6: Session Resumption

```bash
# First connection: save session
openssl s_client -connect google.com:443 -servername google.com \
    -sess_out ~/practice/tls_handshake/session.pem </dev/null 2>&1 \
    | grep -E "Session-ID|TLS session ticket"

echo ""
echo "=== Resuming session ==="
# Second connection: attempt to reuse saved session
openssl s_client -connect google.com:443 -servername google.com \
    -sess_in ~/practice/tls_handshake/session.pem </dev/null 2>&1 \
    | grep -E "Reused\|Resumed\|Session-ID|New\|Reuse"
```

## Task 7: Use a Local CA + Server for Full Handshake Observation

```bash
cd ~/practice/tls_handshake

# Reuse certs from block3/07 if they exist, or create new ones
if [ -f ~/practice/tls/ca.crt ]; then
    cp ~/practice/tls/{ca.crt,ca.key,server.crt,server.key} .
    echo "Reused certs from block3/07 TLS lesson"
else
    openssl genrsa -out ca.key 2048
    openssl req -new -x509 -key ca.key -out ca.crt -days 365 \
        -subj "/CN=Test CA"
    openssl genrsa -out server.key 2048
    openssl req -new -key server.key -out server.csr -subj "/CN=localhost"
    echo "subjectAltName=DNS:localhost,IP:127.0.0.1" > ext.cnf
    openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key \
        -CAcreateserial -out server.crt -days 365 -extfile ext.cnf
fi

# Start a local TLS server in background
openssl s_server -cert server.crt -key server.key -CAfile ca.crt \
    -accept 8443 -www -quiet &
SERVER_PID=$!
sleep 1

# Connect to it and observe
openssl s_client -connect localhost:8443 -CAfile ca.crt -servername localhost \
    </dev/null 2>&1 | grep -E "Verify|Protocol|Cipher|subject|issuer"

# Test with curl
curl -s --cacert ca.crt https://localhost:8443 | head -5

kill $SERVER_PID 2>/dev/null
```

## Task 8: Write a TLS Check Script

```bash
cat > ~/practice/tls_handshake/tls_check.sh << 'EOF'
#!/bin/bash
# Usage: ./tls_check.sh <hostname> [port]
HOST=${1:-google.com}
PORT=${2:-443}

echo "Checking TLS for $HOST:$PORT"

# Protocol and cipher
RESULT=$(openssl s_client -connect "$HOST:$PORT" -servername "$HOST" \
    </dev/null 2>&1)

PROTOCOL=$(echo "$RESULT" | awk '/Protocol/{print $3}')
CIPHER=$(echo "$RESULT" | awk '/Cipher/{print $3}')
VERIFY=$(echo "$RESULT" | grep "Verify return" | head -1)

echo "Protocol: $PROTOCOL"
echo "Cipher:   $CIPHER"
echo "Verify:   $VERIFY"

# Expiry
EXPIRY=$(echo "$RESULT" | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
echo "Expires:  $EXPIRY"
EOF
chmod +x ~/practice/tls_handshake/tls_check.sh
bash ~/practice/tls_handshake/tls_check.sh google.com
```

## Expected Outcome

- `openssl s_client` shows Protocol and Cipher fields
- TLS 1.2 and 1.3 negotiate different cipher suites
- SNI sends the hostname in ClientHello
- ALPN negotiates `h2` for HTTP/2-capable servers
- Session saved to `session.pem` and resume attempt made
- `tls_check.sh` reports protocol, cipher, and expiry for a host
