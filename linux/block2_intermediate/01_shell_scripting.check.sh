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

# Task 1: greet.sh
[[ -f ~/scripts/greet.sh ]] && r="ok" || r="~/scripts/greet.sh not found"
check "greet.sh exists" "$r"

if [[ -f ~/scripts/greet.sh ]]; then
  [[ -x ~/scripts/greet.sh ]] && r="ok" || r="greet.sh is not executable"
  check "greet.sh is executable" "$r"

  output=$(~/scripts/greet.sh Alice 2>&1)
  echo "$output" | grep -q "Alice" && r="ok" || r="greet.sh Alice output: '$output' (expected 'Alice' in output)"
  check "greet.sh Alice prints Alice" "$r"

  ~/scripts/greet.sh > /dev/null 2>&1; code=$?
  [[ $code -ne 0 ]] && r="ok" || r="greet.sh with no args exits 0 (expected non-zero)"
  check "greet.sh no-args exits non-zero" "$r"
fi

# Task 2: counter.sh
[[ -f ~/scripts/counter.sh ]] && r="ok" || r="~/scripts/counter.sh not found"
check "counter.sh exists" "$r"

[[ -f ~/scripts/counter_output.txt ]] && r="ok" || r="counter_output.txt not found"
check "counter_output.txt exists" "$r"

if [[ -f ~/scripts/counter_output.txt ]]; then
  grep -q "^5$\|5" ~/scripts/counter_output.txt && r="ok" || r="counter_output.txt doesn't contain '5'"
  check "counter_output.txt contains 5" "$r"

  grep -qi "done\|counted" ~/scripts/counter_output.txt && r="ok" || r="counter_output.txt missing 'Done' line"
  check "counter_output.txt has 'Done' message" "$r"
fi

# Task 3: find_large.sh
[[ -f ~/scripts/find_large.sh ]] && r="ok" || r="~/scripts/find_large.sh not found"
check "find_large.sh exists" "$r"

[[ -f ~/scripts/large_files.txt ]] && r="ok" || r="large_files.txt not found"
check "large_files.txt exists" "$r"

# Task 4: check_file.sh
[[ -f ~/scripts/check_file.sh ]] && r="ok" || r="~/scripts/check_file.sh not found"
check "check_file.sh exists" "$r"

if [[ -f ~/scripts/check_file.sh ]]; then
  [[ -x ~/scripts/check_file.sh ]] && r="ok" || r="check_file.sh is not executable (chmod +x it)"
  check "check_file.sh is executable" "$r"

  if [[ -x ~/scripts/check_file.sh ]]; then
    output=$(~/scripts/check_file.sh /etc/passwd 2>&1)
    echo "$output" | grep -qi "exists\|exist" && r="ok" || r="check_file.sh /etc/passwd output: '$output' (expected EXISTS)"
    check "check_file.sh reports EXISTS for /etc/passwd" "$r"

    ~/scripts/check_file.sh /etc/passwd > /dev/null 2>&1; code=$?
    [[ $code -eq 0 ]] && r="ok" || r="check_file.sh /etc/passwd exits $code (expected 0)"
    check "check_file.sh exits 0 for existing file" "$r"

    ~/scripts/check_file.sh /nonexistent_xyz > /dev/null 2>&1; code=$?
    [[ $code -ne 0 ]] && r="ok" || r="check_file.sh /nonexistent exits 0 (expected non-zero)"
    check "check_file.sh exits non-zero for missing file" "$r"
  fi
fi

[[ -f ~/scripts/check_output.txt ]] && r="ok" || r="check_output.txt not found"
check "check_output.txt exists" "$r"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
