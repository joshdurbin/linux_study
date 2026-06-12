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

[[ -d ~/servicelab ]] && r="ok" || r="~/servicelab not found"
check "~/servicelab exists" "$r"

# Task 1
[[ -f ~/servicelab/all_services.txt ]] && r="ok" || r="all_services.txt not found"
check "all_services.txt exists" "$r"

if [[ -f ~/servicelab/all_services.txt ]]; then
  grep -q "\.service" ~/servicelab/all_services.txt && r="ok" || r="all_services.txt doesn't contain .service entries"
  check "all_services.txt lists .service units" "$r"
fi

[[ -f ~/servicelab/cron_status.txt ]] && r="ok" || r="cron_status.txt not found"
check "cron_status.txt exists" "$r"

[[ -f ~/servicelab/cron_enabled.txt ]] && r="ok" || r="cron_enabled.txt not found"
check "cron_enabled.txt exists" "$r"

if [[ -f ~/servicelab/cron_enabled.txt ]]; then
  grep -qE "enabled|disabled|static|masked" ~/servicelab/cron_enabled.txt && r="ok" || r="cron_enabled.txt doesn't contain expected systemctl output"
  check "cron_enabled.txt has valid systemctl is-enabled output" "$r"
fi

# Task 2
[[ -f ~/servicelab/journal_recent.txt ]] && r="ok" || r="journal_recent.txt not found"
check "journal_recent.txt exists" "$r"

if [[ -f ~/servicelab/journal_recent.txt ]]; then
  lines=$(wc -l < ~/servicelab/journal_recent.txt)
  [[ $lines -ge 1 ]] && r="ok" || r="journal_recent.txt is empty"
  check "journal_recent.txt has content" "$r"
fi

[[ -f ~/servicelab/journal_errors.txt ]] && r="ok" || r="journal_errors.txt not found"
check "journal_errors.txt exists" "$r"

[[ -f ~/servicelab/kernel_messages.txt ]] && r="ok" || r="kernel_messages.txt not found"
check "kernel_messages.txt exists" "$r"

# Task 3
[[ -f /etc/systemd/system/hello.service ]] && r="ok" || r="/etc/systemd/system/hello.service not found"
check "hello.service unit file exists" "$r"

if [[ -f /etc/systemd/system/hello.service ]]; then
  grep -q "Hello World\|hello" /etc/systemd/system/hello.service && r="ok" || r="hello.service doesn't contain expected content"
  check "hello.service has correct content" "$r"
fi

[[ -f ~/servicelab/hello_status.txt ]] && r="ok" || r="hello_status.txt not found"
check "hello_status.txt exists" "$r"

if [[ -f ~/servicelab/hello_status.txt ]]; then
  grep -qi "active\|inactive\|failed\|hello" ~/servicelab/hello_status.txt && r="ok" || r="hello_status.txt doesn't look like systemctl status output"
  check "hello_status.txt looks like systemctl status" "$r"
fi

# Task 4
[[ -f ~/servicelab/boot_time.txt ]] && r="ok" || r="boot_time.txt not found"
check "boot_time.txt exists" "$r"

[[ -f ~/servicelab/boot_blame.txt ]] && r="ok" || r="boot_blame.txt not found"
check "boot_blame.txt exists" "$r"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
