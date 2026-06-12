# TLS Handshake Internals

Block3/07 taught you to generate and inspect certificates. This lesson covers what happens on the wire when a TLS connection is established — the handshake protocol, version differences, and how to observe and debug it.

## TLS 1.2 Handshake

```
Client                                      Server
  |------ ClientHello ---------------------->|
  |   (TLS version, cipher suites, random)   |
  |                                           |
  |<----- ServerHello ------------------------|
  |   (chosen cipher suite, random)           |
  |<----- Certificate ------------------------|
  |   (server's cert chain)                   |
  |<----- ServerHelloDone ------------------- |
  |                                           |
  |------ ClientKeyExchange --------------->  |
  |   (pre-master secret, encrypted w/ cert) |
  |------ ChangeCipherSpec ----------------> |
  |------ Finished (encrypted) ----------->  |
  |                                           |
  |<----- ChangeCipherSpec -------------------|
  |<----- Finished (encrypted) --------------|
  |                                           |
  |===== Application Data (encrypted) ======>|
```

Two round trips before data flows. TLS 1.2 requires 2-RTT for a new connection.

## TLS 1.3 Handshake

TLS 1.3 reduces to **1-RTT** (new connection) or **0-RTT** (resuming a session):

```
Client                                      Server
  |------ ClientHello + key_share ---------->|
  |   (supported groups, key share)          |
  |                                           |
  |<----- ServerHello + key_share -----------|
  |<----- EncryptedExtensions ---------------|
  |<----- Certificate (encrypted) ----------|
  |<----- CertificateVerify (encrypted) ----|
  |<----- Finished (encrypted) -------------|
  |                                           |
  |------ Finished --------------------------> |
  |===== Application Data ==================>|
```

Differences from 1.2:
- **Fewer round trips** (1-RTT vs 2-RTT)
- **Forward secrecy mandatory** (ECDHE key exchange always)
- **Weak cipher suites removed** (no RC4, 3DES, SHA-1, RSA key exchange)
- **Encrypted earlier** (certificates and extensions are encrypted)

## Observing the Handshake with openssl s_client

`openssl s_client` (from block3/07) is the primary tool for TLS debugging:

```bash
# Basic TLS connection — shows full handshake info
openssl s_client -connect example.com:443 -servername example.com </dev/null 2>&1

# Key fields in the output:
# SSL-Session:
#     Protocol: TLSv1.3          ← version negotiated
#     Cipher:   TLS_AES_256_GCM_SHA384  ← cipher suite
#     Session-ID: ...             ← session resumption ID
#     TLS session ticket: ...     ← for session resumption

# Force TLS 1.2 explicitly
openssl s_client -connect example.com:443 -tls1_2 </dev/null 2>&1 | grep -E "Protocol|Cipher"

# Force TLS 1.3
openssl s_client -connect example.com:443 -tls1_3 </dev/null 2>&1 | grep -E "Protocol|Cipher"

# Show full certificate chain
openssl s_client -connect example.com:443 -showcerts </dev/null 2>&1

# Show cipher suites the server supports
openssl s_client -connect example.com:443 -cipher 'ALL' </dev/null 2>&1 | grep Cipher
```

## TLS with curl

`curl` (block2/03) exposes TLS negotiation details with `-v`:

```bash
# Verbose TLS info
curl -v https://example.com 2>&1 | grep -E "SSL|TLS|issuer|subject|expire"

# Force specific TLS version
curl --tlsv1.2 https://example.com
curl --tlsv1.3 --tls-max 1.3 https://example.com

# Show what curl reports about the cert
curl -v --head https://example.com 2>&1 | grep -E "subject|issuer|expire|SSL"

# Skip cert verification (dev only)
curl -k https://localhost:8443

# Use client certificate for mTLS
curl --cert client.crt --key client.key --cacert ca.crt https://server/

# Check supported TLS version
curl --version | grep -i ssl
```

## SNI — Server Name Indication

SNI allows one server to host multiple TLS certificates on the same IP/port. The client sends the target hostname in the ClientHello (plaintext in TLS 1.2, encrypted in TLS 1.3's ECH extension).

```bash
# Without SNI: server sends its default cert
openssl s_client -connect 93.184.216.34:443 </dev/null 2>/dev/null \
    | openssl x509 -noout -subject

# With SNI: server sends the matching cert
openssl s_client -connect 93.184.216.34:443 -servername example.com </dev/null 2>/dev/null \
    | openssl x509 -noout -subject

# curl always sends SNI automatically based on the URL hostname
```

## ALPN — Application-Layer Protocol Negotiation

ALPN allows the client and server to negotiate which application protocol to use over TLS (HTTP/1.1, h2, etc.) during the handshake, saving a round trip.

```bash
# See what ALPN protocols a server advertises
openssl s_client -connect example.com:443 -alpn h2,http/1.1 </dev/null 2>&1 \
    | grep -E "ALPN|protocol"

# curl shows the negotiated protocol
curl -v --http2 https://example.com 2>&1 | grep -E "ALPN|h2|HTTP"
```

## Session Resumption

TLS session resumption avoids a full handshake for repeat connections:

**Session IDs** (TLS 1.2): server caches session state, client reuses the ID.
**Session tickets** (TLS 1.2 and 1.3): server encrypts session state into a ticket the client stores and presents on reconnect.

```bash
# Show session ticket in output
openssl s_client -connect example.com:443 -sess_out /tmp/sess.pem </dev/null 2>&1 | \
    grep -E "TLS session ticket|Session-ID"

# Reuse the session
openssl s_client -connect example.com:443 -sess_in /tmp/sess.pem </dev/null 2>&1 | \
    grep "Reused\|Resumed\|Session-ID"
```

## Diagnosing TLS Failures

```bash
# Cert validation failure
curl https://self-signed-site.example.com
# curl: (60) SSL certificate problem: self-signed certificate
# Fix: add -k (skip) or --cacert your-ca.crt

# Wrong hostname
openssl s_client -connect 1.2.3.4:443 </dev/null 2>&1 | grep -i "verify\|error"
# verify error:num=18:self-signed certificate
# verify error:num=62:hostname mismatch

# Certificate expired
openssl x509 -in server.crt -checkend 0 || echo "EXPIRED"
openssl s_client -connect example.com:443 </dev/null 2>&1 | openssl x509 -noout -dates

# Protocol mismatch (server only supports TLS 1.2, client requests 1.3)
openssl s_client -connect oldserver.example.com:443 -tls1_3 </dev/null 2>&1 | \
    grep -E "error|handshake"
```

## Further Reading

- [RFC 8446 — TLS 1.3](https://datatracker.ietf.org/doc/html/rfc8446) — The TLS 1.3 specification defining the 1-RTT handshake, mandatory forward secrecy, encrypted handshake messages, and the removal of weak cipher suites shown in this lesson.
- [TLS 1.3 illustrated](https://tls13.xargs.org/) — A byte-by-byte visual walkthrough of a complete TLS 1.3 handshake, annotating every field in every record — the best resource for understanding what `openssl s_client` output actually represents.
- [Julia Evans: A few things I learned about OpenSSL and TLS](https://jvns.ca/blog/2022/01/18/a-few-things-i-learned-about-openssl-about-tls/) — Practical notes on using `openssl s_client` to debug TLS issues, covering certificate inspection, SNI, ALPN, and common error messages.
- [Cloudflare: What happens in a TLS handshake?](https://www.cloudflare.com/learning/ssl/what-happens-in-a-tls-handshake/) — Clear illustrated explanation of TLS 1.2 vs 1.3 handshakes, SNI, ALPN, and session resumption — the same topics covered in this lesson's diagrams.
