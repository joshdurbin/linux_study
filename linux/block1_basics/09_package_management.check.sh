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
[[ -d ~/pkglab ]] && r="ok" || r="~/pkglab not found"
check "~/pkglab exists" "$r"

[[ -f ~/pkglab/installed_packages.txt ]] && r="ok" || r="installed_packages.txt not found"
check "installed_packages.txt exists" "$r"

if [[ -f ~/pkglab/installed_packages.txt ]]; then
  lines=$(wc -l < ~/pkglab/installed_packages.txt)
  [[ $lines -gt 50 ]] && r="ok" || r="installed_packages.txt has only $lines lines (too few packages listed)"
  check "installed_packages.txt has many packages" "$r"
fi

[[ -f ~/pkglab/install_count.txt ]] && r="ok" || r="install_count.txt not found"
check "install_count.txt exists" "$r"

if [[ -f ~/pkglab/install_count.txt ]]; then
  val=$(tr -d '[:space:]' < ~/pkglab/install_count.txt)
  [[ "$val" =~ ^[0-9]+$ && "$val" -gt 10 ]] && r="ok" || r="install_count.txt contains '$val' (expected a number > 10)"
  check "install_count.txt contains a reasonable package count" "$r"
fi

# Task 2
[[ -f ~/pkglab/curl_info.txt ]] && r="ok" || r="curl_info.txt not found"
check "curl_info.txt exists" "$r"

if [[ -f ~/pkglab/curl_info.txt ]]; then
  grep -qi "version\|description" ~/pkglab/curl_info.txt && r="ok" || r="curl_info.txt doesn't look like apt show output"
  check "curl_info.txt contains apt show fields" "$r"
fi

# Task 3
[[ -f ~/pkglab/command_locations.txt ]] && r="ok" || r="command_locations.txt not found"
check "command_locations.txt exists" "$r"

if [[ -f ~/pkglab/command_locations.txt ]]; then
  grep -q "bash\|ls" ~/pkglab/command_locations.txt && r="ok" || r="command_locations.txt doesn't reference bash or ls"
  check "command_locations.txt references bash/ls" "$r"
fi

# Task 4
[[ -f ~/pkglab/bash_files.txt ]] && r="ok" || r="bash_files.txt not found"
check "bash_files.txt exists" "$r"

if [[ -f ~/pkglab/bash_files.txt ]]; then
  lines=$(wc -l < ~/pkglab/bash_files.txt)
  [[ $lines -gt 5 ]] && r="ok" || r="bash_files.txt has only $lines lines (dpkg -L bash should list many files)"
  check "bash_files.txt has many files listed" "$r"
fi

[[ -f ~/pkglab/bash_bins.txt ]] && r="ok" || r="bash_bins.txt not found"
check "bash_bins.txt exists" "$r"

if [[ -f ~/pkglab/bash_bins.txt ]]; then
  grep -q "/bin/" ~/pkglab/bash_bins.txt && r="ok" || r="bash_bins.txt doesn't contain /bin/ paths"
  check "bash_bins.txt contains /bin/ paths" "$r"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
