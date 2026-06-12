# curl, wget, and HTTP

## curl: The Swiss Army Knife of HTTP

`curl` (Client URL) transfers data using URLs. It supports HTTP, HTTPS, FTP, SCP, SFTP, and many other protocols. It's the go-to tool for API testing, debugging web services, and scripting HTTP interactions.

## Essential curl Options

| Option | Meaning |
|--------|---------|
| `-v` | Verbose: show request/response headers |
| `-I` | HEAD request only (just headers, no body) |
| `-L` | Follow redirects (301/302) |
| `-o file` | Save output to file (preserving URL name convention) |
| `-O` | Save output to file with remote filename |
| `-X POST` | Specify HTTP method |
| `-H "Header: value"` | Add a request header |
| `-d "data"` | Send POST data (body) |
| `-u user:pass` | HTTP Basic authentication |
| `-k` | Skip TLS certificate verification |
| `--cacert file` | Use custom CA certificate |
| `-s` | Silent mode (no progress) |
| `-S` | Show errors even in silent mode |
| `-w "%{http_code}"` | Print specific info after transfer |
| `--connect-timeout N` | Timeout for connection (seconds) |
| `-m N` | Max total time (seconds) |

## Common curl One-Liners

```bash
# Simple GET request
curl https://example.com

# Verbose: see full headers
curl -v https://example.com

# Just response headers (HEAD request)
curl -I https://example.com

# Follow redirects and save
curl -L -o output.html https://example.com

# Get just the HTTP status code
curl -s -o /dev/null -w "%{http_code}" https://example.com

# Check if a service is up (exit 0 on 2xx/3xx)
curl -f -s -o /dev/null https://example.com && echo "UP" || echo "DOWN"

# POST JSON data
curl -X POST https://api.example.com/endpoint \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer mytoken" \
  -d '{"key": "value"}'

# POST form data
curl -X POST https://example.com/form \
  -d "username=alice&password=secret"

# Upload a file
curl -X POST https://example.com/upload \
  -F "file=@/path/to/file.txt"

# Basic authentication
curl -u admin:password https://example.com/api

# Custom CA certificate (self-signed)
curl --cacert /path/to/ca.crt https://internal.example.com
```

## Reading verbose curl Output

```bash
curl -v http://example.com
```

```
* Connected to example.com (93.184.216.34) port 80
> GET / HTTP/1.1                ← request line
> Host: example.com             ← request headers
> User-Agent: curl/7.88.1
> Accept: */*
>                               ← blank line = end of headers
< HTTP/1.1 200 OK               ← response status
< Content-Type: text/html       ← response headers
< Content-Length: 1256
<                               ← blank line = start of body
<!doctype html>...              ← response body
```

Lines with `>` are the **request**, lines with `<` are the **response**, lines with `*` are curl's internal info.

## HTTP Status Codes

| Code | Category | Common Codes |
|------|----------|-------------|
| 2xx | Success | 200 OK, 201 Created, 204 No Content |
| 3xx | Redirect | 301 Moved Permanently, 302 Found, 304 Not Modified |
| 4xx | Client Error | 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found |
| 5xx | Server Error | 500 Internal Server Error, 502 Bad Gateway, 503 Service Unavailable |

## Key HTTP Headers

```bash
# Request headers you'd set:
Content-Type: application/json     # format of body you're sending
Authorization: Bearer <token>      # authentication token
Accept: application/json           # format you want in response
Host: api.example.com              # target hostname (required in HTTP/1.1)

# Response headers to look for:
Content-Type: application/json     # format of response body
Location: https://new-url.com      # redirect target
Cache-Control: max-age=3600        # caching directive
Set-Cookie: session=abc123         # set a cookie
X-RateLimit-Remaining: 42          # API rate limit remaining
```

## wget: Recursive Downloads

`wget` is simpler than curl but excels at recursive downloading and resuming.

```bash
# Simple download
wget https://example.com/file.tar.gz

# Download quietly, saving to a specific file
wget -q -O myfile.html https://example.com

# Recursive site download
wget -r -np -l 2 https://docs.example.com

# Continue interrupted download
wget -c https://example.com/bigfile.iso

# Rate limiting
wget --limit-rate=100k https://example.com/file.tar.gz

# No certificate check
wget --no-check-certificate https://self-signed.example.com

# Mirror a site
wget -m https://example.com
```

## Testing HTTP Services

```bash
# Check if a service is responding
curl -sf http://localhost:8080/health && echo "healthy" || echo "unhealthy"

# Test with timeout
curl --connect-timeout 3 -m 5 -sf http://service.local/

# Check specific header
curl -sI https://example.com | grep -i "content-type"

# Test redirects step by step
curl -v -L https://example.com 2>&1 | grep -E "^[<>*]"
```

## Further Reading

- [curl man page](https://curl.se/docs/manpage.html) — Complete reference for every curl option including `--resolve`, `--interface`, `--proxy`, and the full `--write-out` format string variables used in this lesson.
- [Everything curl (free book)](https://everything.curl.dev/) — The authoritative free book by curl's author covering HTTP internals, TLS, authentication, and every curl feature — the best resource for going beyond the one-liners in this lesson.
- [RFC 9110 — HTTP Semantics](https://datatracker.ietf.org/doc/html/rfc9110) — The current HTTP specification defining request methods, status codes, and headers — the ground truth behind the HTTP status code table and header reference in this lesson.
- [MDN: HTTP status codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status) — Practical explanations of every HTTP status code with examples of when servers return each one, making it easy to interpret curl responses in scripts.
