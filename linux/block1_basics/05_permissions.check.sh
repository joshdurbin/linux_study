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

get_perm() {
  stat -c "%a" "$1" 2>/dev/null
}

# Task 1: files with specific permissions
[[ -d ~/permlab ]] && r="ok" || r="~/permlab directory not found"
check "~/permlab exists" "$r"

[[ -f ~/permlab/secret.txt ]] && r="ok" || r="secret.txt not found"
check "secret.txt exists" "$r"

if [[ -f ~/permlab/secret.txt ]]; then
  perm=$(get_perm ~/permlab/secret.txt)
  [[ "$perm" == "600" ]] && r="ok" || r="secret.txt has permissions $perm (expected 600)"
  check "secret.txt has permission 600" "$r"
fi

[[ -f ~/permlab/script.sh ]] && r="ok" || r="script.sh not found"
check "script.sh exists" "$r"

if [[ -f ~/permlab/script.sh ]]; then
  perm=$(get_perm ~/permlab/script.sh)
  [[ "$perm" == "755" ]] && r="ok" || r="script.sh has permissions $perm (expected 755)"
  check "script.sh has permission 755" "$r"
fi

[[ -f ~/permlab/shared.txt ]] && r="ok" || r="shared.txt not found"
check "shared.txt exists" "$r"

# Task 2: permissions_listing.txt
[[ -f ~/permlab/permissions_listing.txt ]] && r="ok" || r="permissions_listing.txt not found"
check "permissions_listing.txt exists" "$r"

if [[ -f ~/permlab/permissions_listing.txt ]]; then
  grep -q "secret\|script\|shared" ~/permlab/permissions_listing.txt && r="ok" || r="permissions_listing.txt doesn't list the expected files"
  check "permissions_listing.txt lists expected files" "$r"
fi

# Task 3: shared.txt should be 740 after symbolic chmod changes
if [[ -f ~/permlab/shared.txt ]]; then
  perm=$(get_perm ~/permlab/shared.txt)
  [[ "$perm" == "740" ]] && r="ok" || r="shared.txt has permissions $perm (expected 740 after symbolic chmod)"
  check "shared.txt has permission 740" "$r"
fi

# Task 4: umask_value.txt and umask_result.txt
[[ -f ~/permlab/umask_value.txt ]] && r="ok" || r="umask_value.txt not found"
check "umask_value.txt exists" "$r"

if [[ -f ~/permlab/umask_value.txt ]]; then
  grep -qE '[0-9]' ~/permlab/umask_value.txt && r="ok" || r="umask_value.txt doesn't contain a number"
  check "umask_value.txt has content" "$r"
fi

[[ -f ~/permlab/umask_result.txt ]] && r="ok" || r="umask_result.txt not found"
check "umask_result.txt exists" "$r"

if [[ -f ~/permlab/umask_result.txt ]]; then
  grep -qE '^[0-9]+' ~/permlab/umask_result.txt && r="ok" || r="umask_result.txt doesn't start with octal digits"
  check "umask_result.txt contains octal permissions" "$r"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
