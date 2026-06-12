#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: curl is installed
check "curl is installed" \
  "command -v curl > /dev/null 2>&1"

# Check 2: curl can reach loopback (start a server and test)
check "curl can make HTTP requests to localhost" \
  "python3 -m http.server 18765 --directory /tmp > /dev/null 2>&1 & sleep 1; STATUS=\$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:18765/ 2>/dev/null); kill %1 2>/dev/null; [[ \$STATUS == '200' ]]"

# Check 3: wget is installed (optional, degraded check)
check "wget or curl is installed" \
  "command -v wget > /dev/null 2>&1 || command -v curl > /dev/null 2>&1"

# Check 4: curl -I (HEAD) works
check "curl -I (HEAD request) works on loopback" \
  "python3 -m http.server 18766 --directory /tmp > /dev/null 2>&1 & sleep 1; curl -sI http://127.0.0.1:18766/ > /dev/null 2>&1; RET=\$?; kill %1 2>/dev/null; [ \$RET -eq 0 ]"

# Check 5: practice directory exists
check "~/practice directory exists" \
  "[ -d \$HOME/practice ]"

# Check 6: curl_notes.txt exists
check "~/practice/curl_notes.txt exists" \
  "[ -f \$HOME/practice/curl_notes.txt ]"

# Check 7: curl_notes.txt is not empty
check "curl_notes.txt is not empty" \
  "[ -s \$HOME/practice/curl_notes.txt ]"

# Check 8: curl_notes.txt contains HTTP status code information
check "curl_notes.txt contains HTTP status code" \
  "grep -qE '(200|404|500|HTTP|status|curl)' \$HOME/practice/curl_notes.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
