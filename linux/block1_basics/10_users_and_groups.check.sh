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
[[ -d ~/userlab ]] && r="ok" || r="~/userlab not found"
check "~/userlab exists" "$r"

[[ -f ~/userlab/whoami.txt ]] && r="ok" || r="whoami.txt not found"
check "whoami.txt exists" "$r"

if [[ -f ~/userlab/whoami.txt ]]; then
  current_user=$(whoami)
  grep -q "$current_user" ~/userlab/whoami.txt && r="ok" || r="whoami.txt doesn't contain '$current_user'"
  check "whoami.txt contains current username" "$r"
fi

[[ -f ~/userlab/id_output.txt ]] && r="ok" || r="id_output.txt not found"
check "id_output.txt exists" "$r"

if [[ -f ~/userlab/id_output.txt ]]; then
  grep -q "uid=" ~/userlab/id_output.txt && r="ok" || r="id_output.txt doesn't contain 'uid='"
  check "id_output.txt contains uid=" "$r"
fi

[[ -f ~/userlab/groups.txt ]] && r="ok" || r="groups.txt not found"
check "groups.txt exists" "$r"

# Task 2
[[ -f ~/userlab/user_count.txt ]] && r="ok" || r="user_count.txt not found"
check "user_count.txt exists" "$r"

if [[ -f ~/userlab/user_count.txt ]]; then
  val=$(tr -d '[:space:]' < ~/userlab/user_count.txt)
  [[ "$val" =~ ^[0-9]+$ && "$val" -gt 5 ]] && r="ok" || r="user_count.txt contains '$val' (expected >5 users)"
  check "user_count.txt has a reasonable user count" "$r"
fi

[[ -f ~/userlab/usernames.txt ]] && r="ok" || r="usernames.txt not found"
check "usernames.txt exists" "$r"

if [[ -f ~/userlab/usernames.txt ]]; then
  grep -q "root" ~/userlab/usernames.txt && r="ok" || r="usernames.txt doesn't contain 'root'"
  check "usernames.txt contains 'root'" "$r"
fi

[[ -f ~/userlab/bash_users.txt ]] && r="ok" || r="bash_users.txt not found"
check "bash_users.txt exists" "$r"

if [[ -f ~/userlab/bash_users.txt ]]; then
  lines=$(wc -l < ~/userlab/bash_users.txt)
  [[ $lines -ge 1 ]] && r="ok" || r="bash_users.txt is empty (expected at least one bash user)"
  check "bash_users.txt has at least one entry" "$r"
fi

# Task 3
[[ -f ~/userlab/groups_db.txt ]] && r="ok" || r="groups_db.txt not found"
check "groups_db.txt exists" "$r"

if [[ -f ~/userlab/groups_db.txt ]]; then
  grep -q "root\|:" ~/userlab/groups_db.txt && r="ok" || r="groups_db.txt doesn't look like /etc/group"
  check "groups_db.txt looks like group database" "$r"
fi

[[ -f ~/userlab/my_groups.txt ]] && r="ok" || r="my_groups.txt not found"
check "my_groups.txt exists" "$r"

# Task 4
[[ -f ~/userlab/has_sudo.txt ]] && r="ok" || r="has_sudo.txt not found"
check "has_sudo.txt exists" "$r"

if [[ -f ~/userlab/has_sudo.txt ]]; then
  val=$(tr -d '[:space:]' < ~/userlab/has_sudo.txt)
  [[ "$val" == "yes" || "$val" == "no" ]] && r="ok" || r="has_sudo.txt contains '$val' (expected 'yes' or 'no')"
  check "has_sudo.txt contains 'yes' or 'no'" "$r"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
