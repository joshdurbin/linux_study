# TLS, Certificates, and PKI

Every service you run in production uses TLS. Understanding the certificate chain, how trust works, and how to inspect and debug certificates is a daily SRE skill.

## PKI Fundamentals

**Public Key Infrastructure (PKI)** is the system of trust that makes TLS work:

- **Private key** — kept secret by the server; used to sign and decrypt
- **Public key** — embedded in the certificate; shared openly
- **Certificate** — binds a public key to an identity (hostname/org), signed by a CA
- **Certificate Authority (CA)** — a trusted third party that signs certificates; its own cert is pre-installed in OS/browser trust stores
- **Certificate chain** — leaf cert → intermediate CA(s) → root CA

When a client connects, it verifies that the leaf certificate was signed by a CA it trusts, following the chain up to a root CA.

## openssl — The Swiss Army Knife for PKI

### Generating Keys and Certificates

```bash
# Generate a 2048-bit RSA private key
openssl genrsa -out server.key 2048

# Generate a self-signed certificate (valid 365 days)
openssl req -new -x509 -key server.key -out server.crt -days 365 \
    -subj "/CN=localhost/O=MyOrg/C=US"

# Two-step: generate a CSR (Certificate Signing Request), then sign it
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr \
    -subj "/CN=myservice.example.com/O=MyOrg"

# Sign the CSR with a CA key and cert
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out server.crt -days 365

# View a certificate's details
openssl x509 -in server.crt -text -noout
```

### Key Certificate Fields

```
Subject: CN=myservice.example.com, O=MyOrg, C=US    ← who this cert is for
Issuer: CN=My CA, O=MyOrg                            ← who signed it
Validity: Not Before / Not After                      ← expiry window
Subject Alternative Names (SAN): DNS:*.example.com   ← what hostnames it covers
Public Key: RSA 2048-bit
Signature Algorithm: sha256WithRSAEncryption
```

The **Subject Alternative Name (SAN)** extension is what browsers check — the CN alone is deprecated.

## Inspecting Live Certificates

```bash
# Connect to a server and show its certificate chain
openssl s_client -connect example.com:443 -servername example.com </dev/null 2>/dev/null \
    | openssl x509 -text -noout

# Quick check: expiry date only
openssl s_client -connect example.com:443 -servername example.com </dev/null 2>/dev/null \
    | openssl x509 -noout -dates

# Show the full certificate chain (leaf + intermediates)
openssl s_client -connect example.com:443 -showcerts </dev/null 2>&1

# Check which TLS version and cipher suite was negotiated
openssl s_client -connect example.com:443 </dev/null 2>&1 | grep -E "Protocol|Cipher"

# Test TLS 1.3 explicitly
openssl s_client -connect example.com:443 -tls1_3 </dev/null 2>&1 | head -10

# Verify a certificate against a CA bundle
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt server.crt
```

## Building a Local CA for Development

```bash
# 1. Create CA key and self-signed cert
openssl genrsa -out ca.key 4096
openssl req -new -x509 -key ca.key -out ca.crt -days 3650 \
    -subj "/CN=Local Dev CA/O=Dev"

# 2. Generate server key and CSR
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr \
    -subj "/CN=localhost"

# 3. Create extensions file (SANs are required by modern clients)
cat > server.ext << 'EOF'
subjectAltName = DNS:localhost, IP:127.0.0.1
EOF

# 4. Sign the server cert with your CA
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out server.crt -days 365 -extfile server.ext

# 5. Verify the chain
openssl verify -CAfile ca.crt server.crt    # should print: server.crt: OK
```

## Testing a TLS Server

```bash
# Simple HTTPS test with curl
curl -v https://localhost:8443 --cacert ca.crt 2>&1 | grep -E "SSL|TLS|cert|issuer"

# Skip cert verification (dev only — never in production)
curl -k https://localhost:8443

# Check days until expiry (useful in monitoring scripts)
openssl s_client -connect example.com:443 -servername example.com </dev/null 2>/dev/null \
    | openssl x509 -noout -enddate \
    | cut -d= -f2 \
    | xargs -I{} date -d "{}" +%s \
    | xargs -I{} bash -c 'echo "Days left: $(( ({} - $(date +%s)) / 86400 ))"'
```

## mTLS — Mutual TLS

In standard TLS, only the server presents a certificate. In **mutual TLS (mTLS)**, both client and server authenticate with certificates. Used in service meshes (Istio), internal APIs, and zero-trust networking.

```bash
# Client cert setup (same CA signs both)
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr -subj "/CN=my-client"
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out client.crt -days 365

# Connect with a client certificate
openssl s_client -connect server:443 \
    -cert client.crt -key client.key \
    -CAfile ca.crt

# curl with client cert
curl --cert client.crt --key client.key --cacert ca.crt https://server/
```

## Certificate File Formats

| Format | Extension | Contents | Common Use |
|--------|-----------|----------|-----------|
| PEM | `.crt`, `.pem`, `.key` | Base64-encoded DER, surrounded by `-----BEGIN...-----` | Everything Linux |
| DER | `.der`, `.cer` | Binary ASN.1 | Java, Windows |
| PKCS#12 | `.p12`, `.pfx` | Combined cert + key (password-protected) | Windows, Java keystores |

```bash
# Convert PEM cert to DER
openssl x509 -in server.crt -outform DER -out server.der

# Convert DER to PEM
openssl x509 -in server.der -inform DER -outform PEM -out server.crt

# Bundle cert + key into PKCS#12
openssl pkcs12 -export -in server.crt -inkey server.key -out server.p12 -passout pass:mypassword

# Inspect PKCS#12
openssl pkcs12 -in server.p12 -nokeys -passin pass:mypassword | openssl x509 -text -noout
```

## Certificate Debugging Patterns

```bash
# Does the certificate match the private key?
diff <(openssl x509 -in server.crt -pubkey -noout) \
     <(openssl rsa -in server.key -pubout 2>/dev/null)

# Check if a cert is expired
openssl x509 -in server.crt -checkend 0 && echo "valid" || echo "EXPIRED"

# Check if it expires within 30 days
openssl x509 -in server.crt -checkend $((30 * 86400)) || echo "expiring within 30 days"

# Which CA signed this cert?
openssl x509 -in server.crt -noout -issuer

# What SANs does it cover?
openssl x509 -in server.crt -noout -ext subjectAltName
```

## Further Reading

- [RFC 8446 — TLS 1.3](https://datatracker.ietf.org/doc/html/rfc8446) — the TLS 1.3 specification: covers the handshake, 0-RTT, the removal of RSA key exchange, and why TLS 1.3 is faster and more secure than TLS 1.2.
- [RFC 5280 — X.509 PKI and Certificate Profiles](https://datatracker.ietf.org/doc/html/rfc5280) — the authoritative specification for X.509 certificate structure, Subject Alternative Names, key usage extensions, and certificate chain validation rules.
- [openssl(1) manual](https://man.openssl.org/master/man1/openssl.html) — official OpenSSL command reference covering `genrsa`, `req`, `x509`, `s_client`, `verify`, and `pkcs12` — the commands used throughout this lesson.
- [Let's Encrypt — How It Works](https://letsencrypt.org/how-it-works/) — explains the ACME protocol used by Let's Encrypt: domain validation, certificate issuance, and the automated renewal flow that production services rely on.
- [Julia Evans — A few things I learned about TLS](https://jvns.ca/blog/2022/01/18/a-few-things-i-learned-about-openssl-about-tls/) — practical explanations of certificate chain debugging, SNI, and common `openssl s_client` patterns for inspecting production TLS configurations.
