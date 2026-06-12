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

# Task 1: directories and files
for d in ~/fileops ~/fileops/originals ~/fileops/backups; do
  [[ -d $d ]] && r="ok" || r="directory $d not found"
  check "$d exists" "$r"
done

for f in alpha.txt beta.txt gamma_renamed.txt; do
  # gamma.txt should be renamed to gamma_renamed.txt
  :
done

[[ -f ~/fileops/originals/alpha.txt ]] && r="ok" || r="alpha.txt not found in originals"
check "originals/alpha.txt exists" "$r"

[[ -f ~/fileops/originals/beta.txt ]] && r="ok" || r="beta.txt not found in originals"
check "originals/beta.txt exists" "$r"

# Check content of alpha.txt
if [[ -f ~/fileops/originals/alpha.txt ]]; then
  grep -q "alpha" ~/fileops/originals/alpha.txt && r="ok" || r="alpha.txt does not contain 'alpha'"
  check "alpha.txt has expected content" "$r"
fi

# Task 2: backups and rename
[[ -f ~/fileops/backups/alpha.txt ]] && r="ok" || r="backups/alpha.txt not found"
check "backups/alpha.txt exists" "$r"

[[ -f ~/fileops/backups/beta.txt ]] && r="ok" || r="backups/beta.txt not found"
check "backups/beta.txt exists" "$r"

[[ -f ~/fileops/originals/gamma_renamed.txt ]] && r="ok" || r="gamma_renamed.txt not found (did you rename gamma.txt?)"
check "gamma_renamed.txt exists" "$r"

[[ ! -f ~/fileops/originals/gamma.txt ]] && r="ok" || r="gamma.txt still exists (should have been renamed)"
check "gamma.txt no longer exists (renamed)" "$r"

# Task 3: symlink
if [[ -L ~/fileops/alpha_link.txt ]]; then
  r="ok"
else
  r="~/fileops/alpha_link.txt is not a symlink (or doesn't exist)"
fi
check "alpha_link.txt is a symlink" "$r"

# Hard link: same inode as alpha.txt
if [[ -f ~/fileops/originals/alpha.txt && -f ~/fileops/originals/alpha_hard.txt ]]; then
  inode1=$(stat -c %i ~/fileops/originals/alpha.txt)
  inode2=$(stat -c %i ~/fileops/originals/alpha_hard.txt)
  [[ "$inode1" == "$inode2" ]] && r="ok" || r="alpha_hard.txt has different inode ($inode2) than alpha.txt ($inode1)"
  check "alpha_hard.txt shares inode with alpha.txt" "$r"
else
  echo "FAIL: alpha_hard.txt or alpha.txt missing — cannot check hard link"
  ((FAIL++))
fi

# Task 4: stat output
[[ -f ~/fileops/stat_output.txt ]] && r="ok" || r="~/fileops/stat_output.txt not found"
check "stat_output.txt exists" "$r"

if [[ -f ~/fileops/stat_output.txt ]]; then
  grep -qi "inode\|size\|access\|modify" ~/fileops/stat_output.txt && r="ok" || r="stat_output.txt doesn't look like stat output"
  check "stat_output.txt contains stat fields" "$r"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
