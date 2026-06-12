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

# tmux installed
command -v tmux >/dev/null 2>&1 && r="ok" || r="tmux not found (sudo apt install tmux)"
check "tmux is installed" "$r"

[[ -d ~/tmuxlab ]] && r="ok" || r="~/tmuxlab not found (mkdir ~/tmuxlab)"
check "~/tmuxlab exists" "$r"

# Task 1: version file
[[ -f ~/tmuxlab/tmux_version.txt ]] && r="ok" || r="tmux_version.txt not found"
check "tmux_version.txt exists" "$r"

if [[ -f ~/tmuxlab/tmux_version.txt ]]; then
  grep -qi "tmux" ~/tmuxlab/tmux_version.txt && r="ok" || r="tmux_version.txt doesn't contain 'tmux'"
  check "tmux_version.txt has tmux version string" "$r"
fi

# Task 2: session-related files
[[ -f ~/tmuxlab/session_list.txt ]] && r="ok" || r="session_list.txt not found (run the session lifecycle exercise)"
check "session_list.txt exists" "$r"

if [[ -f ~/tmuxlab/session_list.txt ]]; then
  grep -q "practice" ~/tmuxlab/session_list.txt && r="ok" || r="session_list.txt doesn't show 'practice' session"
  check "session_list.txt shows 'practice' session" "$r"
fi

# Task 3: .tmux.conf
[[ -f ~/.tmux.conf ]] && r="ok" || r="~/.tmux.conf not found"
check "~/.tmux.conf exists" "$r"

if [[ -f ~/.tmux.conf ]]; then
  grep -q "mouse on" ~/.tmux.conf && r="ok" || r="~/.tmux.conf missing 'set -g mouse on'"
  check "~/.tmux.conf has mouse on" "$r"

  grep -q "base-index 1\|base-index=1" ~/.tmux.conf && r="ok" || r="~/.tmux.conf missing base-index 1"
  check "~/.tmux.conf has base-index 1" "$r"

  grep -q "history-limit" ~/.tmux.conf && r="ok" || r="~/.tmux.conf missing history-limit"
  check "~/.tmux.conf has history-limit" "$r"
fi

# Task 4: setup_session.sh and session_ready.txt
[[ -f ~/tmuxlab/setup_session.sh ]] && r="ok" || r="setup_session.sh not found"
check "setup_session.sh exists" "$r"

if [[ -f ~/tmuxlab/setup_session.sh ]]; then
  [[ -x ~/tmuxlab/setup_session.sh ]] && r="ok" || r="setup_session.sh is not executable"
  check "setup_session.sh is executable" "$r"

  grep -q "tmux" ~/tmuxlab/setup_session.sh && r="ok" || r="setup_session.sh doesn't use tmux"
  check "setup_session.sh uses tmux" "$r"
fi

[[ -f ~/tmuxlab/session_ready.txt ]] && r="ok" || r="session_ready.txt not found (run setup_session.sh)"
check "session_ready.txt exists" "$r"

if [[ -f ~/tmuxlab/session_ready.txt ]]; then
  grep -q "session ready" ~/tmuxlab/session_ready.txt && r="ok" || r="session_ready.txt doesn't contain 'session ready'"
  check "session_ready.txt has expected content" "$r"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
