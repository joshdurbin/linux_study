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
[[ -f ~/advscripts/process.sh ]] && r="ok" || r="process.sh not found"
check "process.sh exists" "$r"

if [[ -f ~/advscripts/process.sh ]]; then
  [[ -x ~/advscripts/process.sh ]] && r="ok" || r="process.sh is not executable"
  check "process.sh is executable" "$r"

  grep -q "set -e\|pipefail" ~/advscripts/process.sh && r="ok" || r="process.sh doesn't use strict mode (set -e or pipefail)"
  check "process.sh uses strict mode" "$r"

  grep -q "getopts" ~/advscripts/process.sh && r="ok" || r="process.sh doesn't use getopts"
  check "process.sh uses getopts" "$r"
fi

[[ -f ~/advscripts/output.txt ]] && r="ok" || r="output.txt not found (run: ~/advscripts/process.sh -v -o ~/advscripts/output.txt ~/advscripts/data)"
check "output.txt exists" "$r"

if [[ -f ~/advscripts/output.txt ]]; then
  grep -q "\.txt\|verbose\|Verbose" ~/advscripts/output.txt && r="ok" || r="output.txt doesn't contain expected content (.txt files or verbose message)"
  check "output.txt has expected content" "$r"
fi

# Task 2
[[ -f ~/advscripts/cleanup_demo.sh ]] && r="ok" || r="cleanup_demo.sh not found"
check "cleanup_demo.sh exists" "$r"

if [[ -f ~/advscripts/cleanup_demo.sh ]]; then
  grep -q "trap" ~/advscripts/cleanup_demo.sh && r="ok" || r="cleanup_demo.sh doesn't use trap"
  check "cleanup_demo.sh uses trap" "$r"

  grep -q "mktemp" ~/advscripts/cleanup_demo.sh && r="ok" || r="cleanup_demo.sh doesn't use mktemp"
  check "cleanup_demo.sh uses mktemp" "$r"
fi

[[ -f ~/advscripts/tempfile_path.txt ]] && r="ok" || r="tempfile_path.txt not found (run cleanup_demo.sh)"
check "tempfile_path.txt exists" "$r"

if [[ -f ~/advscripts/tempfile_path.txt ]]; then
  tmppath=$(tr -d '[:space:]' < ~/advscripts/tempfile_path.txt)
  [[ -n "$tmppath" ]] && r="ok" || r="tempfile_path.txt is empty"
  check "tempfile_path.txt has a path" "$r"

  # The temp file should be gone (trap cleaned it up)
  [[ ! -f "$tmppath" ]] && r="ok" || r="temp file $tmppath still exists (trap didn't clean up)"
  check "temp file was cleaned up by trap" "$r"
fi

# Task 3
[[ -f ~/advscripts/parallel_process.sh ]] && r="ok" || r="parallel_process.sh not found"
check "parallel_process.sh exists" "$r"

if [[ -f ~/advscripts/parallel_process.sh ]]; then
  grep -q "xargs" ~/advscripts/parallel_process.sh && r="ok" || r="parallel_process.sh doesn't use xargs"
  check "parallel_process.sh uses xargs" "$r"

  grep -qE "xargs.*-[Pp]|xargs.*-[Pp] [0-9]" ~/advscripts/parallel_process.sh && r="ok" || r="parallel_process.sh doesn't use xargs -P for parallel execution"
  check "parallel_process.sh uses xargs -P" "$r"
fi

[[ -f ~/advscripts/parallel_output.txt ]] && r="ok" || r="parallel_output.txt not found"
check "parallel_output.txt exists" "$r"

if [[ -f ~/advscripts/parallel_output.txt ]]; then
  lines=$(wc -l < ~/advscripts/parallel_output.txt)
  [[ $lines -ge 3 ]] && r="ok" || r="parallel_output.txt has only $lines lines (expected 6 from 6 files)"
  check "parallel_output.txt has 3+ lines" "$r"
fi

# Task 4
[[ -f ~/advscripts/gen_config.sh ]] && r="ok" || r="gen_config.sh not found"
check "gen_config.sh exists" "$r"

if [[ -f ~/advscripts/gen_config.sh ]]; then
  grep -q "EOF\|heredoc\|cat <<" ~/advscripts/gen_config.sh && r="ok" || r="gen_config.sh doesn't use a heredoc"
  check "gen_config.sh uses heredoc" "$r"
fi

[[ -f ~/advscripts/generated.conf ]] && r="ok" || r="generated.conf not found (run gen_config.sh)"
check "generated.conf exists" "$r"

if [[ -f ~/advscripts/generated.conf ]]; then
  grep -q "hostname=" ~/advscripts/generated.conf && r="ok" || r="generated.conf missing hostname="
  check "generated.conf has hostname" "$r"

  grep -q "user=" ~/advscripts/generated.conf && r="ok" || r="generated.conf missing user="
  check "generated.conf has user" "$r"

  grep -qE "[0-9]{4}-[0-9]{2}-[0-9]{2}" ~/advscripts/generated.conf && r="ok" || r="generated.conf missing date in YYYY-MM-DD format"
  check "generated.conf has date" "$r"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
