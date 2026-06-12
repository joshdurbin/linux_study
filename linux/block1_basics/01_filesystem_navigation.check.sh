#!/bin/bash
set -euo pipefail
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

# Task 1: directory structure
[[ -d ~/practice/notes ]] && r="ok" || r="~/practice/notes directory not found"
check "~/practice/notes exists" "$r"

[[ -d ~/practice/projects/alpha ]] && r="ok" || r="~/practice/projects/alpha not found"
check "~/practice/projects/alpha exists" "$r"

[[ -d ~/practice/projects/beta ]] && r="ok" || r="~/practice/projects/beta not found"
check "~/practice/projects/beta exists" "$r"

# Task 2: etc_listing.txt exists and has content
[[ -f ~/practice/notes/etc_listing.txt ]] && r="ok" || r="~/practice/notes/etc_listing.txt not found"
check "etc_listing.txt exists" "$r"

if [[ -f ~/practice/notes/etc_listing.txt ]]; then
  lines=$(wc -l < ~/practice/notes/etc_listing.txt)
  [[ $lines -gt 5 ]] && r="ok" || r="etc_listing.txt looks empty or too short ($lines lines)"
  check "etc_listing.txt has content" "$r"
fi

# Task 3: conf_files.txt exists and contains .conf paths
[[ -f ~/practice/notes/conf_files.txt ]] && r="ok" || r="~/practice/notes/conf_files.txt not found"
check "conf_files.txt exists" "$r"

if [[ -f ~/practice/notes/conf_files.txt ]]; then
  grep -q "\.conf" ~/practice/notes/conf_files.txt && r="ok" || r="conf_files.txt does not contain any .conf entries"
  check "conf_files.txt contains .conf paths" "$r"
fi

# Task 4: disk_usage.txt exists and contains a size entry
[[ -f ~/practice/notes/disk_usage.txt ]] && r="ok" || r="~/practice/notes/disk_usage.txt not found"
check "disk_usage.txt exists" "$r"

if [[ -f ~/practice/notes/disk_usage.txt ]]; then
  grep -q "practice" ~/practice/notes/disk_usage.txt && r="ok" || r="disk_usage.txt does not mention 'practice'"
  check "disk_usage.txt references practice directory" "$r"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
