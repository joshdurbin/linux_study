# Exercise: curl, wget, and HTTP

## Setup

```bash
mkdir -p ~/practice
which curl || sudo apt-get install -y curl
which wget || sudo apt-get install -y wget
```

## Task 1: Start a Local HTTP Server

We'll use a local server to practice curl without needing internet access:

```bash
# Create some test content
mkdir -p /tmp/httptest
echo "<html><body><h1>Test Page</h1></body></html>" > /tmp/httptest/index.html
echo '{"status": "ok", "service": "test"}' > /tmp/httptest/health.json

# Start HTTP server in background
cd /tmp/httptest && python3 -m http.server 8888 &
HTTP_PID=$!
echo "Server PID: $HTTP_PID"
sleep 1

# Verify it's running
curl -s http://127.0.0.1:8888/ | head -5
```

## Task 2: Make Various curl Requests

```bash
# Simple GET
curl http://127.0.0.1:8888/

# Verbose output (see request/response headers)
curl -v http://127.0.0.1:8888/index.html 2>&1

# HEAD request (headers only)
curl -I http://127.0.0.1:8888/

# Save the HTTP status code
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8888/)
echo "HTTP status: $STATUS"

# Request a non-existent file (should be 404)
STATUS404=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8888/notexist)
echo "404 test status: $STATUS404"
```

## Task 3: Save Verbose Output with Headers

```bash
curl -v http://127.0.0.1:8888/ > ~/practice/curl_notes.txt 2>&1
echo "Saved curl output to ~/practice/curl_notes.txt"
cat ~/practice/curl_notes.txt
```

## Task 4: Practice Custom Headers and Methods

```bash
# Add custom headers
curl -H "Accept: application/json" \
     -H "X-Custom-Header: test" \
     http://127.0.0.1:8888/health.json

# Look at what headers python's HTTP server sees (check server output)
curl -v http://127.0.0.1:8888/health.json 2>&1 | grep "^[><*]"
```

## Task 5: Follow Redirects

```bash
# Create a redirect test (if you have netcat)
# Demonstrate with a real redirect if internet is available
curl -v -L http://127.0.0.1:8888/ 2>&1 | grep -E "HTTP|Location|Connected"
```

## Task 6: Use wget

```bash
# Download a file with wget
wget -q -O /tmp/wget_test.html http://127.0.0.1:8888/index.html
cat /tmp/wget_test.html

# Download quietly, save with remote name
cd /tmp && wget -q http://127.0.0.1:8888/health.json
cat /tmp/health.json
```

## Task 7: Add HTTP Status Code to Notes

```bash
cat >> ~/practice/curl_notes.txt << 'EOF'

=== HTTP Status Codes Reference ===
200 - OK (success)
201 - Created (POST success)
301 - Moved Permanently (permanent redirect)
302 - Found (temporary redirect)
400 - Bad Request (malformed request)
401 - Unauthorized (need authentication)
403 - Forbidden (not allowed)
404 - Not Found
500 - Internal Server Error
502 - Bad Gateway
503 - Service Unavailable
EOF
```

## Cleanup

```bash
kill $HTTP_PID 2>/dev/null || true
```

## Expected Outcome

- `~/practice/curl_notes.txt` exists and contains HTTP status code information
- You can make GET/HEAD requests with curl and read the verbose output
- You understand HTTP status code categories (2xx, 3xx, 4xx, 5xx)
