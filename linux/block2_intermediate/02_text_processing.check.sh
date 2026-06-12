#!/bin/bash
PASS=0
FAIL=0

check() {
  local desc="$1"
  local result="$2"
  if [[ "$result" == "ok" ]]; then
    echo "PASS: $desc"
    ((PASS++))
  else
    echo "FAIL: $desc — $result"
    ((FAIL++))
  fi
}

[[ -d ~/textlab ]] && r="ok" || r="~/textlab not found"
check "~/textlab exists" "$r"

[[ -f ~/textlab/access.log ]] && r="ok" || r="access.log not found (did you create the setup data?)"
check "access.log exists" "$r"

# Task 1a: ips.txt
[[ -f ~/textlab/ips.txt ]] && r="ok" || r="ips.txt not found"
check "ips.txt exists" "$r"

if [[ -f ~/textlab/ips.txt ]]; then
  grep -qE "^[0-9]+\.[0-9]+" ~/textlab/ips.txt && r="ok" || r="ips.txt doesn't look like IP addresses"
  check "ips.txt contains IP addresses" "$r"
  lines=$(wc -l < ~/textlab/ips.txt)
  [[ $lines -eq 8 ]] && r="ok" || r="ips.txt has $lines lines (expected 8, one per log entry)"
  check "ips.txt has 8 lines" "$r"
fi

# Task 1b: ok_requests.txt (200 status)
[[ -f ~/textlab/ok_requests.txt ]] && r="ok" || r="ok_requests.txt not found"
check "ok_requests.txt exists" "$r"

if [[ -f ~/textlab/ok_requests.txt ]]; then
  grep -qv "401\|500\|404" ~/textlab/ok_requests.txt || true
  lines=$(wc -l < ~/textlab/ok_requests.txt)
  [[ $lines -eq 5 ]] && r="ok" || r="ok_requests.txt has $lines lines (expected 5 lines with status 200)"
  check "ok_requests.txt has 5 lines (all 200s)" "$r"
fi

# Task 1c: total_bytes.txt — should contain a number
[[ -f ~/textlab/total_bytes.txt ]] && r="ok" || r="total_bytes.txt not found"
check "total_bytes.txt exists" "$r"

if [[ -f ~/textlab/total_bytes.txt ]]; then
  grep -qE '[0-9]+' ~/textlab/total_bytes.txt && r="ok" || r="total_bytes.txt doesn't contain a number"
  check "total_bytes.txt contains a number" "$r"
fi

# Task 2a: modified_log.txt with HTTP-GET
[[ -f ~/textlab/modified_log.txt ]] && r="ok" || r="modified_log.txt not found"
check "modified_log.txt exists" "$r"

if [[ -f ~/textlab/modified_log.txt ]]; then
  grep -q "HTTP-GET" ~/textlab/modified_log.txt && r="ok" || r="modified_log.txt doesn't contain 'HTTP-GET'"
  check "modified_log.txt contains HTTP-GET" "$r"
fi

# Task 2b: no404_log.txt
[[ -f ~/textlab/no404_log.txt ]] && r="ok" || r="no404_log.txt not found"
check "no404_log.txt exists" "$r"

if [[ -f ~/textlab/no404_log.txt ]]; then
  grep -q "404" ~/textlab/no404_log.txt && r="FAIL: no404_log.txt still contains 404 lines" || r="ok"
  check "no404_log.txt has no 404 lines" "$r"
  lines=$(wc -l < ~/textlab/no404_log.txt)
  [[ $lines -eq 7 ]] && r="ok" || r="no404_log.txt has $lines lines (expected 7 after removing the 404 line)"
  check "no404_log.txt has 7 lines" "$r"
fi

# Task 3: ip_counts.txt and ip_counts_sorted.txt
[[ -f ~/textlab/ip_counts.txt ]] && r="ok" || r="ip_counts.txt not found"
check "ip_counts.txt exists" "$r"

if [[ -f ~/textlab/ip_counts.txt ]]; then
  grep -qE '[0-9]+.*[0-9]+\.' ~/textlab/ip_counts.txt && r="ok" || r="ip_counts.txt doesn't look like uniq -c output with IPs"
  check "ip_counts.txt has count+IP format" "$r"
fi

[[ -f ~/textlab/ip_counts_sorted.txt ]] && r="ok" || r="ip_counts_sorted.txt not found"
check "ip_counts_sorted.txt exists" "$r"

# Task 4: user_uids.txt
[[ -f ~/textlab/user_uids.txt ]] && r="ok" || r="user_uids.txt not found"
check "user_uids.txt exists" "$r"

if [[ -f ~/textlab/user_uids.txt ]]; then
  grep -q "root" ~/textlab/user_uids.txt && r="ok" || r="user_uids.txt doesn't contain 'root'"
  check "user_uids.txt contains root" "$r"
fi

[[ -f ~/textlab/user_uids_sorted.txt ]] && r="ok" || r="user_uids_sorted.txt not found"
check "user_uids_sorted.txt exists" "$r"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
