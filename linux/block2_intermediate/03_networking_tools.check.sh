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

[[ -d ~/netlab ]] && r="ok" || r="~/netlab not found"
check "~/netlab exists" "$r"

# Task 1: headers.txt
[[ -f ~/netlab/headers.txt ]] && r="ok" || r="headers.txt not found"
check "headers.txt exists" "$r"

if [[ -f ~/netlab/headers.txt ]]; then
  lines=$(wc -l < ~/netlab/headers.txt)
  [[ $lines -ge 1 ]] && r="ok" || r="headers.txt is empty"
  check "headers.txt has content" "$r"
fi

[[ -f ~/netlab/status_200.txt ]] && r="ok" || r="status_200.txt not found"
check "status_200.txt exists" "$r"

# Task 2: listening_ports.txt
[[ -f ~/netlab/listening_ports.txt ]] && r="ok" || r="listening_ports.txt not found"
check "listening_ports.txt exists" "$r"

if [[ -f ~/netlab/listening_ports.txt ]]; then
  # ss -tuln output should contain at least a header line
  lines=$(wc -l < ~/netlab/listening_ports.txt)
  [[ $lines -ge 1 ]] && r="ok" || r="listening_ports.txt is empty"
  check "listening_ports.txt has content" "$r"
fi

[[ -f ~/netlab/port_count.txt ]] && r="ok" || r="port_count.txt not found"
check "port_count.txt exists" "$r"

if [[ -f ~/netlab/port_count.txt ]]; then
  val=$(tr -d '[:space:]' < ~/netlab/port_count.txt)
  [[ "$val" =~ ^[0-9]+$ ]] && r="ok" || r="port_count.txt contains '$val' (expected a number)"
  check "port_count.txt contains a number" "$r"
fi

# Task 3: ip_addr.txt and ipv4_addrs.txt
[[ -f ~/netlab/ip_addr.txt ]] && r="ok" || r="ip_addr.txt not found"
check "ip_addr.txt exists" "$r"

if [[ -f ~/netlab/ip_addr.txt ]]; then
  grep -q "inet\|link\|lo" ~/netlab/ip_addr.txt && r="ok" || r="ip_addr.txt doesn't look like ip addr output"
  check "ip_addr.txt looks like ip addr output" "$r"
fi

[[ -f ~/netlab/ipv4_addrs.txt ]] && r="ok" || r="ipv4_addrs.txt not found"
check "ipv4_addrs.txt exists" "$r"

if [[ -f ~/netlab/ipv4_addrs.txt ]]; then
  grep -q "inet " ~/netlab/ipv4_addrs.txt && r="ok" || r="ipv4_addrs.txt doesn't contain 'inet ' entries"
  check "ipv4_addrs.txt contains inet entries" "$r"
fi

# Task 4: google_ips.txt and github_ips.txt
[[ -f ~/netlab/google_ips.txt ]] && r="ok" || r="google_ips.txt not found"
check "google_ips.txt exists" "$r"

if [[ -f ~/netlab/google_ips.txt ]]; then
  lines=$(wc -l < ~/netlab/google_ips.txt)
  [[ $lines -ge 1 ]] && r="ok" || r="google_ips.txt is empty"
  check "google_ips.txt has content" "$r"
fi

[[ -f ~/netlab/github_ips.txt ]] && r="ok" || r="github_ips.txt not found"
check "github_ips.txt exists" "$r"

# Verify tools exist
command -v ss >/dev/null 2>&1 && r="ok" || r="ss command not found"
check "ss is installed" "$r"

command -v ip >/dev/null 2>&1 && r="ok" || r="ip command not found"
check "ip is installed" "$r"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
