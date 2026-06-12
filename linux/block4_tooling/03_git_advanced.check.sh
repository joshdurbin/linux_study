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

command -v git >/dev/null 2>&1 && r="ok" || r="git not found"
check "git is installed" "$r"

[[ -d ~/gitlab/.git ]] && r="ok" || r="~/gitlab is not a git repo (run the setup first)"
check "~/gitlab is a git repo" "$r"

# Task 1: stash
[[ -f ~/gitlab/stash_list.txt ]] && r="ok" || r="stash_list.txt not found"
check "stash_list.txt exists" "$r"

if [[ -f ~/gitlab/stash_list.txt ]]; then
  grep -qi "experimental\|stash@{" ~/gitlab/stash_list.txt && r="ok" || r="stash_list.txt doesn't show a stash entry"
  check "stash_list.txt shows stash with message" "$r"
fi

[[ -f ~/gitlab/stash_applied.txt ]] && r="ok" || r="stash_applied.txt not found"
check "stash_applied.txt exists" "$r"

# Task 2: rebase
[[ -f ~/gitlab/log_after_rebase.txt ]] && r="ok" || r="log_after_rebase.txt not found"
check "log_after_rebase.txt exists" "$r"

if [[ -f ~/gitlab/log_after_rebase.txt ]]; then
  grep -qi "wip" ~/gitlab/log_after_rebase.txt && r="FAIL: WIP commit still in log (should be squashed)" || r="ok"
  check "WIP commit is gone after rebase" "$r"

  grep -qi "features\|feature" ~/gitlab/log_after_rebase.txt && r="ok" || r="log_after_rebase.txt missing the squashed commit message"
  check "log_after_rebase.txt shows squashed commit" "$r"
fi

# Task 3: cherry-pick
[[ -f ~/gitlab/log_after_cherry_pick.txt ]] && r="ok" || r="log_after_cherry_pick.txt not found"
check "log_after_cherry_pick.txt exists" "$r"

if [[ -f ~/gitlab/log_after_cherry_pick.txt ]]; then
  grep -qi "fix\|critical\|hotfix\|cherry" ~/gitlab/log_after_cherry_pick.txt && r="ok" || r="log_after_cherry_pick.txt doesn't show the cherry-picked fix commit"
  check "log_after_cherry_pick.txt has fix commit" "$r"
fi

# Task 4: reflog
[[ -f ~/gitlab/reflog_output.txt ]] && r="ok" || r="reflog_output.txt not found"
check "reflog_output.txt exists" "$r"

if [[ -f ~/gitlab/reflog_output.txt ]]; then
  lines=$(wc -l < ~/gitlab/reflog_output.txt)
  [[ $lines -ge 3 ]] && r="ok" || r="reflog_output.txt has only $lines lines (expected multiple entries)"
  check "reflog_output.txt has multiple entries" "$r"

  grep -q "rebase\|cherry-pick\|commit\|HEAD" ~/gitlab/reflog_output.txt && r="ok" || r="reflog_output.txt doesn't look like git reflog output"
  check "reflog_output.txt looks like git reflog" "$r"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
