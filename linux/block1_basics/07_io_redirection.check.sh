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

# Task 1: stdout.txt, stderr.txt, both.txt
[[ -d ~/iolab ]] && r="ok" || r="~/iolab not found"
check "~/iolab exists" "$r"

[[ -f ~/iolab/stdout.txt ]] && r="ok" || r="stdout.txt not found"
check "stdout.txt exists" "$r"

if [[ -f ~/iolab/stdout.txt ]]; then
  grep -q "etc" ~/iolab/stdout.txt && r="ok" || r="stdout.txt doesn't contain /etc listing"
  check "stdout.txt contains /etc directory listing" "$r"
fi

[[ -f ~/iolab/stderr.txt ]] && r="ok" || r="stderr.txt not found"
check "stderr.txt exists" "$r"

if [[ -f ~/iolab/stderr.txt ]]; then
  # stderr should contain the error about nonexistent path, not the /etc listing
  grep -qi "cannot\|no such\|error\|nonexistent" ~/iolab/stderr.txt && r="ok" || r="stderr.txt doesn't contain an error message"
  check "stderr.txt contains error message" "$r"
fi

[[ -f ~/iolab/both.txt ]] && r="ok" || r="both.txt not found"
check "both.txt exists" "$r"

if [[ -f ~/iolab/both.txt ]]; then
  # both.txt should have content from stdout (etc listing) AND stderr (error)
  lines=$(wc -l < ~/iolab/both.txt)
  [[ $lines -ge 2 ]] && r="ok" || r="both.txt has only $lines lines (expected combined stdout+stderr)"
  check "both.txt has combined output" "$r"
fi

# Task 2: combined.txt, tee_copy.txt, line_count.txt
[[ -f ~/iolab/combined.txt ]] && r="ok" || r="combined.txt not found"
check "combined.txt exists" "$r"

if [[ -f ~/iolab/combined.txt ]]; then
  lines=$(wc -l < ~/iolab/combined.txt)
  [[ $lines -ge 2 ]] && r="ok" || r="combined.txt has $lines lines (expected 2)"
  check "combined.txt has 2 lines" "$r"

  grep -q "first line" ~/iolab/combined.txt && r="ok" || r="combined.txt missing 'first line'"
  check "combined.txt contains 'first line'" "$r"

  grep -q "second line" ~/iolab/combined.txt && r="ok" || r="combined.txt missing 'second line'"
  check "combined.txt contains 'second line'" "$r"
fi

[[ -f ~/iolab/tee_copy.txt ]] && r="ok" || r="tee_copy.txt not found"
check "tee_copy.txt exists" "$r"

[[ -f ~/iolab/line_count.txt ]] && r="ok" || r="line_count.txt not found"
check "line_count.txt exists" "$r"

if [[ -f ~/iolab/line_count.txt ]]; then
  val=$(tr -d '[:space:]' < ~/iolab/line_count.txt)
  [[ "$val" == "2" ]] && r="ok" || r="line_count.txt contains '$val' (expected 2)"
  check "line_count.txt contains 2" "$r"
fi

# Task 3: config.ini with heredoc content
[[ -f ~/iolab/config.ini ]] && r="ok" || r="config.ini not found"
check "config.ini exists" "$r"

if [[ -f ~/iolab/config.ini ]]; then
  grep -q "\[server\]" ~/iolab/config.ini && r="ok" || r="config.ini missing [server] section"
  check "config.ini has [server] section" "$r"

  grep -q "host=localhost" ~/iolab/config.ini && r="ok" || r="config.ini missing host=localhost"
  check "config.ini has host=localhost" "$r"

  grep -q "port=8080" ~/iolab/config.ini && r="ok" || r="config.ini missing port=8080"
  check "config.ini has port=8080" "$r"
fi

# Task 4: conf_search.txt
[[ -f ~/iolab/conf_search.txt ]] && r="ok" || r="conf_search.txt not found"
check "conf_search.txt exists" "$r"

if [[ -f ~/iolab/conf_search.txt ]]; then
  grep -q "\.conf" ~/iolab/conf_search.txt && r="ok" || r="conf_search.txt doesn't contain .conf paths"
  check "conf_search.txt contains .conf paths" "$r"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
