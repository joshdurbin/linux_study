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

# Task 1
[[ -d ~/envlab ]] && r="ok" || r="~/envlab not found"
check "~/envlab exists" "$r"

[[ -f ~/envlab/env_snapshot.txt ]] && r="ok" || r="env_snapshot.txt not found"
check "env_snapshot.txt exists" "$r"

if [[ -f ~/envlab/env_snapshot.txt ]]; then
  grep -q "=" ~/envlab/env_snapshot.txt && r="ok" || r="env_snapshot.txt doesn't look like env output (no = signs)"
  check "env_snapshot.txt contains variable assignments" "$r"
fi

[[ -f ~/envlab/path_value.txt ]] && r="ok" || r="path_value.txt not found"
check "path_value.txt exists" "$r"

if [[ -f ~/envlab/path_value.txt ]]; then
  grep -q "/" ~/envlab/path_value.txt && r="ok" || r="path_value.txt doesn't look like a PATH value"
  check "path_value.txt contains a path" "$r"
fi

# Task 2
[[ -f ~/envlab/greeting.txt ]] && r="ok" || r="greeting.txt not found"
check "greeting.txt exists" "$r"

if [[ -f ~/envlab/greeting.txt ]]; then
  grep -q "hello" ~/envlab/greeting.txt && r="ok" || r="greeting.txt doesn't contain 'hello'"
  check "greeting.txt contains 'hello'" "$r"
fi

[[ -f ~/envlab/home_value.txt ]] && r="ok" || r="home_value.txt not found"
check "home_value.txt exists" "$r"

if [[ -f ~/envlab/home_value.txt ]]; then
  grep -q "/" ~/envlab/home_value.txt && r="ok" || r="home_value.txt doesn't look like a path"
  check "home_value.txt contains a path" "$r"
fi

[[ -f ~/envlab/user_value.txt ]] && r="ok" || r="user_value.txt not found"
check "user_value.txt exists" "$r"

if [[ -f ~/envlab/user_value.txt ]]; then
  val=$(tr -d '[:space:]' < ~/envlab/user_value.txt)
  [[ -n "$val" ]] && r="ok" || r="user_value.txt is empty"
  check "user_value.txt has content" "$r"
fi

# Task 3: exit_codes.txt
[[ -f ~/envlab/exit_codes.txt ]] && r="ok" || r="exit_codes.txt not found"
check "exit_codes.txt exists" "$r"

if [[ -f ~/envlab/exit_codes.txt ]]; then
  lines=$(wc -l < ~/envlab/exit_codes.txt)
  [[ $lines -ge 3 ]] && r="ok" || r="exit_codes.txt has only $lines lines (expected 4)"
  check "exit_codes.txt has 3+ lines" "$r"

  # Check that 0 appears (for successful commands)
  grep -qE ":\s*0" ~/envlab/exit_codes.txt && r="ok" || r="exit_codes.txt doesn't show any 0 exit codes"
  check "exit_codes.txt contains 0 exit code" "$r"
fi

# Task 4: new_path.txt starting with /usr/local/sbin
[[ -f ~/envlab/new_path.txt ]] && r="ok" || r="new_path.txt not found"
check "new_path.txt exists" "$r"

if [[ -f ~/envlab/new_path.txt ]]; then
  grep -q "/usr/local/sbin" ~/envlab/new_path.txt && r="ok" || r="new_path.txt doesn't contain /usr/local/sbin"
  check "new_path.txt contains /usr/local/sbin" "$r"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
