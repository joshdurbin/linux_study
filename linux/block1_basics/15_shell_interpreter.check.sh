#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: /etc/shells exists and is readable
check "/etc/shells is readable" \
  "[ -r /etc/shells ] && grep -q '/bin' /etc/shells"

# Check 2: /bin/sh exists
check "/bin/sh exists" \
  "[ -x /bin/sh ]"

# Check 3: /bin/bash exists
check "/bin/bash exists" \
  "[ -x /bin/bash ]"

# Check 4: $SHELL is set
check "\$SHELL is set" \
  "[ -n \"\$SHELL\" ]"

# Check 5: readlink /proc/\$\$/exe returns a path
check "readlink /proc/\$\$/exe returns interpreter path" \
  "readlink /proc/\$\$/exe 2>/dev/null | grep -q '/'"

# Check 6: bash supports [[ ]]
check "bash supports [[ ]] syntax" \
  "bash -c '[[ 1 -eq 1 ]]' 2>/dev/null"

# Check 7: sh does not support [[ ]] (expected to fail)
check "sh does not support [[ ]] (dash behavior)" \
  "! sh -c '[[ 1 -eq 1 ]]' 2>/dev/null"

# Check 8: practice/interpreter directory exists
check "~/practice/interpreter directory exists" \
  "[ -d \$HOME/practice/interpreter ]"

# Check 9: bash_script.sh exists with bash shebang
check "bash_script.sh exists" \
  "[ -f \$HOME/practice/interpreter/bash_script.sh ]"

check "bash_script.sh has a bash shebang" \
  "head -1 \$HOME/practice/interpreter/bash_script.sh | grep -q '#!/'"

# Check 11: sh_script.sh exists with sh-compatible syntax
check "sh_script.sh exists" \
  "[ -f \$HOME/practice/interpreter/sh_script.sh ]"

check "sh_script.sh runs successfully under sh" \
  "sh \$HOME/practice/interpreter/sh_script.sh > /dev/null 2>&1"

# Check 13: detect_shell.sh exists and runs under bash
check "detect_shell.sh exists" \
  "[ -f \$HOME/practice/interpreter/detect_shell.sh ]"

check "detect_shell.sh runs successfully under bash" \
  "bash \$HOME/practice/interpreter/detect_shell.sh > /dev/null 2>&1"

# Check 15: /bin/sh is a valid POSIX shell (accepts POSIX syntax)
check "/bin/sh accepts basic POSIX syntax" \
  "sh -c '[ 1 -eq 1 ] && echo ok' > /dev/null 2>&1"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
