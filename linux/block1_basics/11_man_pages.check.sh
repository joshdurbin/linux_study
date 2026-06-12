#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "man_sections.txt exists"           "[[ -f ~/practice/man_sections.txt ]]"
check "man_sections.txt has passwd"       "grep -qi 'passwd' ~/practice/man_sections.txt"
check "man_sections.txt has signal"       "grep -qi 'signal\|open\|syscall' ~/practice/man_sections.txt"

check "man_apropos.txt exists"            "[[ -f ~/practice/man_apropos.txt ]]"
check "man_apropos.txt is non-empty"      "[[ -s ~/practice/man_apropos.txt ]]"

check "man_whatis.txt exists"             "[[ -f ~/practice/man_whatis.txt ]]"
check "man_whatis.txt has 5 commands"     "[[ $(wc -l < ~/practice/man_whatis.txt) -ge 5 ]]"

check "man_grep_synopsis.txt exists"      "[[ -f ~/practice/man_grep_synopsis.txt ]]"
check "man_grep_synopsis.txt has content" "[[ -s ~/practice/man_grep_synopsis.txt ]]"

check "man_syscall_read.txt exists"       "[[ -f ~/practice/man_syscall_read.txt ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
