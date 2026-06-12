#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: true exits 0
check "true exits with code 0" \
  "true; [ \$? -eq 0 ]"

# Check 2: false exits 1
check "false exits with code 1" \
  "false; [ \$? -eq 1 ]"

# Check 3: non-zero exit on missing path
check "ls of nonexistent path exits non-zero" \
  "ls /nonexistent_path_xyz 2>/dev/null; [ \$? -ne 0 ]"

# Check 4: streams practice directory exists
check "~/practice/streams directory exists" \
  "[ -d \$HOME/practice/streams ]"

# Check 5: found.txt was created
check "found.txt exists" \
  "[ -f \$HOME/practice/streams/found.txt ]"

# Check 6: errors.txt was created
check "errors.txt exists" \
  "[ -f \$HOME/practice/streams/errors.txt ]"

# Check 7: warn.sh exists and uses >&2
check "warn.sh exists" \
  "[ -f \$HOME/practice/streams/warn.sh ]"

check "warn.sh uses >&2 for stderr" \
  "grep -q '>&2' \$HOME/practice/streams/warn.sh"

# Check 9: xargs is available
check "xargs is available" \
  "command -v xargs > /dev/null 2>&1"

# Check 10: xargs passes stdin as arguments
check "xargs passes all stdin tokens as arguments" \
  "[ \"\$(echo 'a b c' | xargs echo)\" = 'a b c' ]"

# Check 11: xargs -n limits arguments per call
check "xargs -n1 runs one invocation per token" \
  "[ \"\$(printf 'x\ny\nz\n' | xargs -n1 echo | wc -l | tr -d ' ')\" -eq 3 ]"

# Check 12: xargs -I{} substitution
check "xargs -I{} substitutes correctly" \
  "[ \"\$(echo hello | xargs -I{} echo {} world)\" = 'hello world' ]"

# Check 13: find -print0 | xargs -0 is safe with spaces
check "find -print0 | xargs -0 handles filenames with spaces" \
  "tmp=\$(mktemp -d) && touch \"\$tmp/has space.txt\" && find \"\$tmp\" -name '*.txt' -print0 | xargs -0 ls > /dev/null 2>&1 && rm -rf \"\$tmp\""

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
