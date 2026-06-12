#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: history command is available
check "history command is available" \
  "type history > /dev/null 2>&1"

# Check 2: history produces output
check "history produces numbered output" \
  "history 1 | grep -qE '^[[:space:]]*[0-9]+'"

# Check 3: ~/.bash_history exists (history has been written)
check "~/.bash_history file exists" \
  "[ -f \$HOME/.bash_history ]"

# Check 4: HISTSIZE can be set
check "HISTSIZE variable is settable" \
  "HISTSIZE=50000; [ \"\$HISTSIZE\" = '50000' ]"

# Check 5: HISTFILESIZE can be set
check "HISTFILESIZE variable is settable" \
  "HISTFILESIZE=100000; [ \"\$HISTFILESIZE\" = '100000' ]"

# Check 6: HISTCONTROL can be set to ignoreboth
check "HISTCONTROL can be set to ignoreboth" \
  "HISTCONTROL=ignoreboth; [ \"\$HISTCONTROL\" = 'ignoreboth' ]"

# Check 7: HISTTIMEFORMAT can be set
check "HISTTIMEFORMAT can be set" \
  "HISTTIMEFORMAT='%F %T '; [ -n \"\$HISTTIMEFORMAT\" ]"

# Check 8: history -w writes to HISTFILE
check "history -w writes history to disk" \
  "history -w 2>/dev/null; [ -f \"\${HISTFILE:-\$HOME/.bash_history}\" ]"

# Check 9: shopt -s histappend sets append mode
check "shopt -s histappend enables append mode" \
  "shopt -s histappend && shopt histappend | grep -q 'on'"

# Check 10: history directory exists
check "~/practice/history directory exists" \
  "[ -d \$HOME/practice/history ]"

# Check 11: histsetup.sh exists
check "histsetup.sh exists" \
  "[ -f \$HOME/practice/history/histsetup.sh ]"

# Check 12: histsetup.sh sets HISTSIZE
check "histsetup.sh sets HISTSIZE" \
  "grep -q 'HISTSIZE' \$HOME/practice/history/histsetup.sh"

# Check 13: histsetup.sh sets HISTCONTROL
check "histsetup.sh sets HISTCONTROL" \
  "grep -q 'HISTCONTROL' \$HOME/practice/history/histsetup.sh"

# Check 14: histsetup.sh uses histappend
check "histsetup.sh enables histappend" \
  "grep -q 'histappend' \$HOME/practice/history/histsetup.sh"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
