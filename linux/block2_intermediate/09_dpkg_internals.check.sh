#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "dpkg_curl_files.txt exists" "[[ -f ~/practice/dpkg_curl_files.txt ]]"
check "dpkg_curl_files.txt has /usr/bin/curl" "grep -q '/usr/bin/curl' ~/practice/dpkg_curl_files.txt"
check "dpkg_find_owner.txt exists" "[[ -f ~/practice/dpkg_find_owner.txt ]]"
check "dpkg_find_owner.txt mentions findutils" "grep -qi 'findutils' ~/practice/dpkg_find_owner.txt"
check "dpkg_rc_packages.txt exists" "[[ -f ~/practice/dpkg_rc_packages.txt ]]"
check "dpkg_bash_info.txt exists" "[[ -f ~/practice/dpkg_bash_info.txt ]]"
check "dpkg_bash_info.txt has /bin/bash" "grep -q '/bin/bash' ~/practice/dpkg_bash_info.txt"
check "dpkg_deb_info.txt exists" "[[ -f ~/practice/dpkg_deb_info.txt ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
