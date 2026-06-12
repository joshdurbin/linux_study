# Exercise: TLS, Certificates, and PKI

## Setup

```bash
mkdir -p ~/practice/tls
cd ~/practice/tls
```

## Task 1: Generate a CA and Server Certificate

```bash
cd ~/practice/tls

# Step 1: Create a CA key and self-signed certificate
openssl genrsa -out ca.key 2048
openssl req -new -x509 -key ca.key -out ca.crt -days 3650 \
    -subj "/CN=Practice CA/O=StudyLab/C=US"

echo "CA certificate created:"
openssl x509 -in ca.crt -noout -subject -issuer -dates
```

```bash
# Step 2: Generate a server key and CSR
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr \
    -subj "/CN=localhost/O=StudyLab"

echo "CSR created. Subject:"
openssl req -in server.csr -noout -subject
```

```bash
# Step 3: Create SAN extension file and sign the cert
cat > server.ext << 'EOF'
subjectAltName = DNS:localhost, IP:127.0.0.1
EOF

openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out server.crt -days 365 -extfile server.ext

echo "Server certificate signed. Verifying chain:"
openssl verify -CAfile ca.crt server.crt
```

## Task 2: Inspect the Certificate

```bash
cd ~/practice/tls

# Full certificate details
openssl x509 -in server.crt -text -noout

# Just the key fields
echo "Subject:" && openssl x509 -in server.crt -noout -subject
echo "Issuer:"  && openssl x509 -in server.crt -noout -issuer
echo "Dates:"   && openssl x509 -in server.crt -noout -dates
echo "SANs:"    && openssl x509 -in server.crt -noout -ext subjectAltName 2>/dev/null || \
                   openssl x509 -in server.crt -noout -text | grep -A2 "Subject Alternative"
```

## Task 3: Verify Key-Certificate Match

```bash
cd ~/practice/tls

# Extract the public key from both cert and key, compare them
CERT_PUB=$(openssl x509 -in server.crt -pubkey -noout)
KEY_PUB=$(openssl rsa -in server.key -pubout 2>/dev/null)

if [ "$CERT_PUB" = "$KEY_PUB" ]; then
    echo "MATCH: certificate and key belong together"
else
    echo "MISMATCH: certificate and key do NOT match"
fi
```

## Task 4: Check Certificate Expiry

```bash
cd ~/practice/tls

# Check if the cert is currently valid
openssl x509 -in server.crt -checkend 0 \
    && echo "Certificate is currently valid" \
    || echo "Certificate is EXPIRED"

# Check if it expires within 30 days (365-day cert, so this should pass)
openssl x509 -in server.crt -checkend $((30 * 86400)) \
    && echo "Not expiring within 30 days" \
    || echo "WARNING: expires within 30 days"

# Days remaining
END=$(openssl x509 -in server.crt -noout -enddate | cut -d= -f2)
echo "Expires: $END"
```

## Task 5: Connect to a Live Server

```bash
# Inspect the certificate chain of a real server
openssl s_client -connect google.com:443 -servername google.com </dev/null 2>/dev/null \
    | openssl x509 -text -noout | grep -E "Subject:|Issuer:|Not After"

# Check TLS protocol and cipher negotiated
openssl s_client -connect google.com:443 </dev/null 2>&1 \
    | grep -E "^Protocol|^Cipher"
```

## Task 6: Generate Client Certificate for mTLS

```bash
cd ~/practice/tls

# Generate client key and CSR
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr \
    -subj "/CN=practice-client/O=StudyLab"

# Sign with the same CA
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out client.crt -days 365

echo "Client certificate:"
openssl x509 -in client.crt -noout -subject -issuer

# Verify both server and client certs against the CA
openssl verify -CAfile ca.crt server.crt
openssl verify -CAfile ca.crt client.crt
```

## Task 7: Write a Certificate Expiry Check Script

```bash
cat > ~/practice/tls/check_cert.sh << 'EOF'
#!/bin/bash
# Usage: ./check_cert.sh <cert_file> [warn_days]
CERT=${1:-server.crt}
WARN_DAYS=${2:-30}

if [ ! -f "$CERT" ]; then
    echo "ERROR: $CERT not found" >&2
    exit 1
fi

# Check if expired
if ! openssl x509 -in "$CERT" -checkend 0 > /dev/null 2>&1; then
    echo "CRITICAL: $CERT is EXPIRED"
    exit 2
fi

# Check warning threshold
SECONDS_LEFT=$((WARN_DAYS * 86400))
if ! openssl x509 -in "$CERT" -checkend "$SECONDS_LEFT" > /dev/null 2>&1; then
    ENDDATE=$(openssl x509 -in "$CERT" -noout -enddate | cut -d= -f2)
    echo "WARNING: $CERT expires within ${WARN_DAYS} days ($ENDDATE)"
    exit 1
fi

ENDDATE=$(openssl x509 -in "$CERT" -noout -enddate | cut -d= -f2)
echo "OK: $CERT valid until $ENDDATE"
exit 0
EOF
chmod +x ~/practice/tls/check_cert.sh
bash ~/practice/tls/check_cert.sh ~/practice/tls/server.crt 30
```

## Expected Outcome

- `~/practice/tls/ca.crt` and `ca.key` — local CA
- `~/practice/tls/server.crt` and `server.key` — server cert signed by the CA
- `~/practice/tls/client.crt` and `client.key` — client cert for mTLS
- `openssl verify` confirms both certs chain to the CA
- `check_cert.sh` reports validity status and warns on upcoming expiry
