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

# vim must be installed
command -v vim >/dev/null 2>&1 && r="ok" || r="vim not found (install with: sudo apt install vim)"
check "vim is installed" "$r"

[[ -d ~/vimlab ]] && r="ok" || r="~/vimlab not found"
check "~/vimlab exists" "$r"

# Task 1: poem.txt
[[ -f ~/vimlab/poem.txt ]] && r="ok" || r="poem.txt not found (create it with vim)"
check "poem.txt exists" "$r"

if [[ -f ~/vimlab/poem.txt ]]; then
  lines=$(wc -l < ~/vimlab/poem.txt)
  [[ $lines -ge 4 ]] && r="ok" || r="poem.txt has only $lines lines (expected 5)"
  check "poem.txt has at least 4 lines" "$r"

  grep -qi "roses\|violets\|linux\|end" ~/vimlab/poem.txt && r="ok" || r="poem.txt doesn't contain expected poem content"
  check "poem.txt has poem content" "$r"
fi

# Task 2: after substitution, poem.txt should have crimson and azure
if [[ -f ~/vimlab/poem.txt ]]; then
  grep -q "crimson" ~/vimlab/poem.txt && r="ok" || r="poem.txt doesn't contain 'crimson' (did you do the substitution?)"
  check "poem.txt contains 'crimson'" "$r"

  grep -q "azure" ~/vimlab/poem.txt && r="ok" || r="poem.txt doesn't contain 'azure' (did you do the substitution?)"
  check "poem.txt contains 'azure'" "$r"

  # red and blue should be gone
  grep -q "^Roses are red$" ~/vimlab/poem.txt && r="FAIL: 'Roses are red' still present (should be 'crimson')" || r="ok"
  check "original 'red' line replaced" "$r"
fi

# Task 3: config.ini
[[ -f ~/vimlab/config.ini ]] && r="ok" || r="config.ini not found"
check "config.ini exists" "$r"

if [[ -f ~/vimlab/config.ini ]]; then
  grep -q "\[database\]" ~/vimlab/config.ini && r="ok" || r="config.ini missing [database] section"
  check "config.ini has [database] section" "$r"

  grep -q "host=localhost" ~/vimlab/config.ini && r="ok" || r="config.ini missing host=localhost"
  check "config.ini has host=localhost" "$r"
fi

# Task 4: vim_version.txt and done.txt
[[ -f ~/vimlab/vim_version.txt ]] && r="ok" || r="vim_version.txt not found"
check "vim_version.txt exists" "$r"

if [[ -f ~/vimlab/vim_version.txt ]]; then
  grep -qi "vim\|version\|VIM" ~/vimlab/vim_version.txt && r="ok" || r="vim_version.txt doesn't look like vim --version output"
  check "vim_version.txt contains version info" "$r"
fi

[[ -f ~/vimlab/done.txt ]] && r="ok" || r="done.txt not found"
check "done.txt exists" "$r"

if [[ -f ~/vimlab/done.txt ]]; then
  grep -qi "complete" ~/vimlab/done.txt && r="ok" || r="done.txt doesn't contain 'complete'"
  check "done.txt contains 'complete'" "$r"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
