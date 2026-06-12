# HTTP/2 and HTTP/3

HTTP/1.1 is 25 years old and its limitations — one request per connection, head-of-line blocking, verbose ASCII headers — are well understood. HTTP/2 and HTTP/3 solve these problems at the protocol layer.

## HTTP/1.1 Limitations

```
Client: GET /index.html HTTP/1.1\r\n    ← one request at a time
         Host: example.com\r\n
         \r\n
Server: HTTP/1.1 200 OK\r\n            ← wait for response before next request
```

**Head-of-line blocking**: a slow response blocks all subsequent requests on that connection. Browsers work around this with 6 parallel connections per host — wasteful and bounded.

## HTTP/2: Binary, Multiplexed, Compressed

HTTP/2 is a binary protocol with four key improvements:

### 1. Multiplexing
Multiple requests/responses fly over a **single TCP connection** simultaneously, identified by stream IDs:

```
Connection: TCP to example.com:443
  Stream 1: GET /style.css  → 200 OK (CSS)
  Stream 3: GET /app.js     → 200 OK (JS)
  Stream 5: GET /image.png  → 200 OK (PNG)
  (all in-flight simultaneously, out of order)
```

### 2. Header Compression (HPACK)
HTTP headers are compressed using a shared dynamic table. Repeated headers (cookies, user-agent) are sent as references, not full strings. Reduces overhead by 85–95%.

### 3. Server Push
Server can proactively send resources before the client asks (e.g., push CSS when serving HTML). Largely abandoned in practice — browsers often prefer cache.

### 4. Stream Prioritization
Clients hint which streams are more important. Server can deliver them first.

### HTTP/2 Still Uses TCP
HTTP/2's multiplexing removes HTTP-level head-of-line blocking but TCP-level head-of-line blocking remains. A single lost packet stalls ALL streams until TCP retransmits it.

## HTTP/3: QUIC Instead of TCP

HTTP/3 replaces TCP with **QUIC**, a UDP-based transport built by Google:

| Feature | TCP + TLS 1.3 | QUIC (HTTP/3) |
|---------|--------------|--------------|
| Connection setup | 1-RTT TLS + 1-RTT TCP = 2 RTT | 1-RTT combined |
| Resumption | 0-RTT possible | 0-RTT built-in |
| Head-of-line blocking | TCP-level (affects all streams) | None (each stream independent) |
| Connection migration | IP change = new connection | Supports IP migration (mobile) |
| Encryption | Optional, TLS on top | Mandatory, built into QUIC |

### 0-RTT Resumption
Returning users get their first HTTP request in the same packet as the TLS handshake — zero round trips before data.

```
[SYN + ClientHello + HTTP request]
                                  ← [ServerHello + HTTP response]
Application data already flowing!
```

## curl and HTTP/2

`curl` (block2/03) supports HTTP/2 when built with nghttp2:

```bash
# Check if curl has HTTP/2 support
curl --version | grep -i http2

# Force HTTP/2 explicitly
curl --http2 -v https://example.com 2>&1 | grep -E "HTTP/2|h2"

# Force HTTP/2 prior knowledge (h2c — HTTP/2 cleartext, no TLS)
curl --http2-prior-knowledge http://localhost:8080/

# Show the protocol version used
curl -sI --http2 https://google.com | head -5
# HTTP/2 200 ← confirmed HTTP/2

# Compare: force HTTP/1.1
curl --http1.1 -sI https://google.com | head -5
# HTTP/1.1 200

# Verbose: see ALPN negotiation and stream IDs
curl -v --http2 https://google.com 2>&1 | grep -E "h2|ALPN|stream"
```

## curl and HTTP/3

HTTP/3 support requires curl built with ngtcp2 or quiche (newer builds):

```bash
# Check for HTTP/3 support
curl --version | grep -i http3

# Use HTTP/3 if available
curl --http3 https://cloudflare.com

# Fallback: HTTP/3 is attempted, falls back to HTTP/2
curl --http3-only https://cloudflare.com   # strict HTTP/3 only
```

## Observing HTTP/2 with openssl

```bash
# See ALPN negotiate h2 (HTTP/2)
openssl s_client -connect google.com:443 -alpn 'h2,http/1.1' </dev/null 2>&1 \
    | grep -E "ALPN|Protocol"

# Send an HTTP/2 upgrade manually (HTTP/2 over TLS is always h2, not h2c)
# HTTP/2 is binary — you can't easily hand-type it like HTTP/1.1
```

## HTTP/2 with a Simple Server (Python)

```bash
# Python's http.server speaks HTTP/1.1. To test HTTP/2 locally, use:
# - nghttp2's nghttpd (if installed)
# - caddy server (static binary)
# - Any modern web server (nginx 1.9.5+, Apache 2.4.17+)

# Check if nghttpd is available
command -v nghttpd 2>/dev/null && echo "nghttpd available" || echo "not installed"

# nginx with HTTP/2 (if nginx is installed)
nginx -V 2>&1 | grep http_v2
```

## What HTTP/2 Means for SREs

```bash
# Fewer connections: one TCP connection per domain instead of 6
# This changes how you tune:
ss -s                              # fewer total connections
sysctl net.netfilter.nf_conntrack_count   # lower conntrack usage

# But multiplexing can cause bursts:
# 100 assets fetched over 1 connection → all in a single TCP burst
# Monitor: ss -ti to see per-connection throughput

# HTTP/2 PUSH is deprecated in Chrome (2022): most servers have it disabled
# HTTP/3 requires UDP 443 to be open — check firewalls:
sudo iptables -L -n | grep -i udp
```

## Diagnosing HTTP/2 Issues

```bash
# Is the server serving HTTP/2?
curl -sI --http2 https://yourdomain.com | head -1
# HTTP/2 200  ← yes
# HTTP/1.1 200  ← no (TLS negotiation succeeded but h2 not offered)

# Did ALPN negotiate h2?
openssl s_client -connect yourdomain.com:443 -alpn 'h2,http/1.1' </dev/null 2>&1 \
    | grep ALPN

# Is HTTP/3 available? (QUIC advertisement)
curl -sI https://yourdomain.com | grep -i "alt-svc"
# alt-svc: h3=":443"; ma=86400  ← server advertises HTTP/3 on port 443

# Trace HTTP/2 frames (requires Wireshark or tshark with http2 dissector)
# tshark -i eth0 -Y http2 -T fields -e http2.streamid -e http2.type 2>/dev/null
```

## Further Reading

- [RFC 9113 — HTTP/2](https://datatracker.ietf.org/doc/html/rfc9113) — The current HTTP/2 specification defining binary framing, stream multiplexing (stream IDs), HPACK header compression, and flow control.
- [RFC 9114 — HTTP/3](https://datatracker.ietf.org/doc/html/rfc9114) — The HTTP/3 specification defining the QUIC-based transport, removing TCP head-of-line blocking and enabling 0-RTT connection establishment.
- [HTTP/2 explained (free book)](https://http2-explained.haxx.se/) — A free book by curl's author Daniel Stenberg covering multiplexing, HPACK, server push, and how HTTP/2 changes the performance characteristics observed in the SRE section of this lesson.
- [HTTP/3 explained (free book)](https://http3-explained.haxx.se/) — The companion book covering QUIC transport, 0-RTT resumption, connection migration, and why HTTP/3 requires UDP 443 to be unblocked at the firewall.
- [Cloudflare: HTTP/3 — the past, present, and future](https://blog.cloudflare.com/http3-the-past-present-and-future/) — Cloudflare's production experience with HTTP/3 deployment, covering the `alt-svc` advertisement mechanism and real-world performance measurements.
