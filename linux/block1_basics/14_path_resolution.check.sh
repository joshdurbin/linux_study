#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: type classifies ls as a file
check "type identifies ls as a file" \
  "type -t ls 2>/dev/null | grep -q 'file'"

# Check 2: type identifies cd as a builtin
check "type identifies cd as a builtin" \
  "type -t cd 2>/dev/null | grep -q 'builtin'"

# Check 3: which finds ls
check "which finds ls" \
  "which ls > /dev/null 2>&1"

# Check 4: which does not find cd (builtin)
check "which does not find cd (builtin)" \
  "! which cd > /dev/null 2>&1"

# Check 5: command -v works for existence check
check "command -v ls exits 0 (found)" \
  "command -v ls > /dev/null 2>&1"

check "command -v nonexistent_xyz exits non-zero (not found)" \
  "! command -v nonexistent_cmd_xyz_99 > /dev/null 2>&1"

# Check 7: hash command is available
check "hash is a shell builtin" \
  "type -t hash | grep -q 'builtin'"

# Check 8: hash -r clears the cache
check "hash -r clears the command cache" \
  "hash -r 2>/dev/null; hash 2>/dev/null | grep -qv '[a-z]' || hash 2>/dev/null | wc -c | grep -q '^0$'"

# Check 9: PATH contains at least 3 directories
check "PATH has at least 3 entries" \
  "[ \"\$(echo \$PATH | tr ':' '\n' | wc -l)\" -ge 3 ]"

# Check 10: PATH contains /usr/bin
check "PATH contains /usr/bin" \
  "echo \$PATH | tr ':' '\n' | grep -q '^/usr/bin$'"

# Check 11: practice/path directory exists
check "~/practice/path directory exists" \
  "[ -d \$HOME/practice/path ]"

# Check 12: check_tools.sh exists
check "check_tools.sh exists" \
  "[ -f \$HOME/practice/path/check_tools.sh ]"

# Check 13: check_tools.sh uses command -v
check "check_tools.sh uses command -v" \
  "grep -q 'command -v' \$HOME/practice/path/check_tools.sh"

# Check 14: prepending to PATH makes a script findable
check "prepending dir to PATH makes scripts in it findable" \
  "tmpdir=\$(mktemp -d) && printf '#!/bin/bash\necho ok\n' > \$tmpdir/testcmd_xyz && chmod +x \$tmpdir/testcmd_xyz && PATH=\"\$tmpdir:\$PATH\" command -v testcmd_xyz > /dev/null 2>&1 && rm -rf \$tmpdir"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
