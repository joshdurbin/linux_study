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

# Task 1: logs.txt exists with correct content
[[ -f ~/searchlab/logs.txt ]] && r="ok" || r="~/searchlab/logs.txt not found"
check "logs.txt exists" "$r"

if [[ -f ~/searchlab/logs.txt ]]; then
  grep -qi "error" ~/searchlab/logs.txt && r="ok" || r="logs.txt does not contain 'error'"
  check "logs.txt contains error entries" "$r"

  lines=$(wc -l < ~/searchlab/logs.txt)
  [[ $lines -ge 6 ]] && r="ok" || r="logs.txt has only $lines lines (expected 6+)"
  check "logs.txt has at least 6 lines" "$r"
fi

# Task 2a: errors.txt — case-insensitive error matches
[[ -f ~/searchlab/errors.txt ]] && r="ok" || r="~/searchlab/errors.txt not found"
check "errors.txt exists" "$r"

if [[ -f ~/searchlab/errors.txt ]]; then
  count=$(wc -l < ~/searchlab/errors.txt)
  # logs.txt has 3 lines matching error/ERROR case-insensitively
  [[ $count -ge 2 ]] && r="ok" || r="errors.txt has only $count lines (expected 3 error lines)"
  check "errors.txt has 2+ error matches" "$r"
fi

# Task 2b: root_files.txt — filenames only from /etc grep
[[ -f ~/searchlab/root_files.txt ]] && r="ok" || r="~/searchlab/root_files.txt not found"
check "root_files.txt exists" "$r"

if [[ -f ~/searchlab/root_files.txt ]]; then
  count=$(wc -l < ~/searchlab/root_files.txt)
  [[ $count -ge 1 ]] && r="ok" || r="root_files.txt is empty — /etc should have files mentioning 'root'"
  check "root_files.txt has at least 1 result" "$r"
fi

# Task 3a: conf_list.txt
[[ -f ~/searchlab/conf_list.txt ]] && r="ok" || r="~/searchlab/conf_list.txt not found"
check "conf_list.txt exists" "$r"

if [[ -f ~/searchlab/conf_list.txt ]]; then
  grep -q "\.conf" ~/searchlab/conf_list.txt && r="ok" || r="conf_list.txt doesn't contain .conf paths"
  check "conf_list.txt contains .conf entries" "$r"
fi

# Task 3b: recent_files.txt
[[ -f ~/searchlab/recent_files.txt ]] && r="ok" || r="~/searchlab/recent_files.txt not found"
check "recent_files.txt exists" "$r"

# Task 4: info_count.txt — just a number
[[ -f ~/searchlab/info_count.txt ]] && r="ok" || r="~/searchlab/info_count.txt not found"
check "info_count.txt exists" "$r"

if [[ -f ~/searchlab/info_count.txt ]]; then
  val=$(tr -d '[:space:]' < ~/searchlab/info_count.txt)
  [[ "$val" =~ ^[0-9]+$ ]] && r="ok" || r="info_count.txt contains '$val' (expected a number)"
  check "info_count.txt contains a number" "$r"

  # logs.txt has 2 INFO lines
  [[ "$val" -ge 1 ]] && r="ok" || r="info_count.txt shows 0 — expected at least 1 INFO line"
  check "info_count.txt is non-zero" "$r"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
