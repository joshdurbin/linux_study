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

# Task 1: sample.txt with 30+ lines
[[ -f ~/viewtest/sample.txt ]] && r="ok" || r="~/viewtest/sample.txt not found"
check "sample.txt exists" "$r"

if [[ -f ~/viewtest/sample.txt ]]; then
  lines=$(wc -l < ~/viewtest/sample.txt)
  [[ $lines -ge 30 ]] && r="ok" || r="sample.txt has only $lines lines (need at least 30)"
  check "sample.txt has at least 30 lines" "$r"
fi

# Task 2: wc_output.txt
[[ -f ~/viewtest/wc_output.txt ]] && r="ok" || r="~/viewtest/wc_output.txt not found"
check "wc_output.txt exists" "$r"

if [[ -f ~/viewtest/wc_output.txt ]]; then
  # wc output contains numbers
  grep -qE '[0-9]+' ~/viewtest/wc_output.txt && r="ok" || r="wc_output.txt doesn't contain numbers"
  check "wc_output.txt contains wc data" "$r"
fi

# Task 3: file_types.txt with 3 lines about 3 files
[[ -f ~/viewtest/file_types.txt ]] && r="ok" || r="~/viewtest/file_types.txt not found"
check "file_types.txt exists" "$r"

if [[ -f ~/viewtest/file_types.txt ]]; then
  lines=$(wc -l < ~/viewtest/file_types.txt)
  [[ $lines -ge 3 ]] && r="ok" || r="file_types.txt has $lines lines (expected at least 3)"
  check "file_types.txt has 3+ lines" "$r"

  grep -q "passwd\|ls\|sample" ~/viewtest/file_types.txt && r="ok" || r="file_types.txt doesn't reference expected files"
  check "file_types.txt references expected files" "$r"
fi

# Task 4: hex_output.txt
[[ -f ~/viewtest/hex_output.txt ]] && r="ok" || r="~/viewtest/hex_output.txt not found"
check "hex_output.txt exists" "$r"

if [[ -f ~/viewtest/hex_output.txt ]]; then
  grep -qE '^[0-9a-f]+' ~/viewtest/hex_output.txt && r="ok" || r="hex_output.txt doesn't look like hexdump output"
  check "hex_output.txt contains hex addresses" "$r"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
