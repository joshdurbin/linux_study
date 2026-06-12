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

command -v jq >/dev/null 2>&1 && r="ok" || r="jq not found (sudo apt install jq)"
check "jq is installed" "$r"

[[ -d ~/jqlab ]] && r="ok" || r="~/jqlab not found"
check "~/jqlab exists" "$r"

# Setup data
[[ -f ~/jqlab/users.json ]] && r="ok" || r="users.json not found (create the setup data)"
check "users.json exists" "$r"

if [[ -f ~/jqlab/users.json ]]; then
  jq '.' ~/jqlab/users.json > /dev/null 2>&1 && r="ok" || r="users.json is not valid JSON"
  check "users.json is valid JSON" "$r"
fi

# Task 1a: pretty.json
[[ -f ~/jqlab/pretty.json ]] && r="ok" || r="pretty.json not found"
check "pretty.json exists" "$r"

# Task 1b: names.txt
[[ -f ~/jqlab/names.txt ]] && r="ok" || r="names.txt not found"
check "names.txt exists" "$r"

if [[ -f ~/jqlab/names.txt ]]; then
  grep -q "Alice" ~/jqlab/names.txt && r="ok" || r="names.txt doesn't contain 'Alice'"
  check "names.txt contains Alice" "$r"

  lines=$(wc -l < ~/jqlab/names.txt)
  [[ $lines -eq 4 ]] && r="ok" || r="names.txt has $lines lines (expected 4 names)"
  check "names.txt has 4 names" "$r"
fi

# Task 1c: user3.json
[[ -f ~/jqlab/user3.json ]] && r="ok" || r="user3.json not found"
check "user3.json exists" "$r"

if [[ -f ~/jqlab/user3.json ]]; then
  grep -q "Carol" ~/jqlab/user3.json && r="ok" || r="user3.json doesn't contain 'Carol' (user id=3)"
  check "user3.json contains Carol" "$r"
fi

# Task 1d: user_count.txt
[[ -f ~/jqlab/user_count.txt ]] && r="ok" || r="user_count.txt not found"
check "user_count.txt exists" "$r"

if [[ -f ~/jqlab/user_count.txt ]]; then
  val=$(tr -d '[:space:]' < ~/jqlab/user_count.txt)
  [[ "$val" == "4" ]] && r="ok" || r="user_count.txt contains '$val' (expected 4)"
  check "user_count.txt is 4" "$r"
fi

# Task 2a: active_users.json
[[ -f ~/jqlab/active_users.json ]] && r="ok" || r="active_users.json not found"
check "active_users.json exists" "$r"

if [[ -f ~/jqlab/active_users.json ]]; then
  # Should not contain Bob (active: false)
  grep -q "Bob" ~/jqlab/active_users.json && r="FAIL: active_users.json contains Bob (who is inactive)" || r="ok"
  check "active_users.json excludes Bob (inactive)" "$r"

  grep -q "Alice" ~/jqlab/active_users.json && r="ok" || r="active_users.json missing Alice"
  check "active_users.json includes Alice" "$r"
fi

# Task 2b: admin_names.txt
[[ -f ~/jqlab/admin_names.txt ]] && r="ok" || r="admin_names.txt not found"
check "admin_names.txt exists" "$r"

if [[ -f ~/jqlab/admin_names.txt ]]; then
  grep -q "Alice" ~/jqlab/admin_names.txt && r="ok" || r="admin_names.txt missing Alice (admin)"
  check "admin_names.txt contains Alice" "$r"
  grep -q "Dave" ~/jqlab/admin_names.txt && r="ok" || r="admin_names.txt missing Dave (admin)"
  check "admin_names.txt contains Dave" "$r"
fi

# Task 2c: avg_score.txt
[[ -f ~/jqlab/avg_score.txt ]] && r="ok" || r="avg_score.txt not found"
check "avg_score.txt exists" "$r"

if [[ -f ~/jqlab/avg_score.txt ]]; then
  grep -qE '^[0-9]+' ~/jqlab/avg_score.txt && r="ok" || r="avg_score.txt doesn't contain a number"
  check "avg_score.txt contains a number" "$r"
fi

# Task 2d: id_name.json
[[ -f ~/jqlab/id_name.json ]] && r="ok" || r="id_name.json not found"
check "id_name.json exists" "$r"

if [[ -f ~/jqlab/id_name.json ]]; then
  grep -q '"name"' ~/jqlab/id_name.json && r="ok" || r="id_name.json doesn't have name field"
  check "id_name.json has name field" "$r"
fi

# Task 3: yq (optional, check if yq available)
if command -v yq >/dev/null 2>&1; then
  [[ -f ~/jqlab/config.yaml ]] && r="ok" || r="config.yaml not found"
  check "config.yaml exists" "$r"

  [[ -f ~/jqlab/app_name.txt ]] && r="ok" || r="app_name.txt not found"
  check "app_name.txt exists" "$r"

  if [[ -f ~/jqlab/app_name.txt ]]; then
    grep -q "myapp" ~/jqlab/app_name.txt && r="ok" || r="app_name.txt doesn't contain 'myapp'"
    check "app_name.txt contains myapp" "$r"
  fi

  [[ -f ~/jqlab/config.json ]] && r="ok" || r="config.json not found"
  check "config.json (converted from yaml) exists" "$r"
else
  echo "SKIP: yq not installed — skipping yq checks"
fi

# Task 4: high_scorers.txt
[[ -f ~/jqlab/high_scorers.txt ]] && r="ok" || r="high_scorers.txt not found"
check "high_scorers.txt exists" "$r"

if [[ -f ~/jqlab/high_scorers.txt ]]; then
  grep -q "Alice" ~/jqlab/high_scorers.txt && r="ok" || r="high_scorers.txt missing Alice (score 95)"
  check "high_scorers.txt contains Alice" "$r"

  grep -q "Carol" ~/jqlab/high_scorers.txt && r="ok" || r="high_scorers.txt missing Carol (score 88)"
  check "high_scorers.txt contains Carol" "$r"

  grep -q "Bob" ~/jqlab/high_scorers.txt && r="FAIL: high_scorers.txt contains Bob (score 72, not > 80)" || r="ok"
  check "high_scorers.txt excludes Bob" "$r"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
