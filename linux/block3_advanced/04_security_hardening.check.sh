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

[[ -d ~/seclab ]] && r="ok" || r="~/seclab not found"
check "~/seclab exists" "$r"

# Task 1
[[ -f ~/seclab/capabilities.txt ]] && r="ok" || r="capabilities.txt not found"
check "capabilities.txt exists" "$r"

[[ -f ~/seclab/setuid_bins.txt ]] && r="ok" || r="setuid_bins.txt not found"
check "setuid_bins.txt exists" "$r"

if [[ -f ~/seclab/setuid_bins.txt ]]; then
  # setuid_bins.txt might be empty if no setuid binaries exist, that's ok
  r="ok"
  check "setuid_bins.txt is valid (may be empty)" "$r"
fi

# Check that getcap is available
command -v getcap >/dev/null 2>&1 && r="ok" || r="getcap not found (install libcap2-bin)"
check "getcap is installed" "$r"

# Task 2
[[ -f ~/seclab/sudo_privs.txt ]] && r="ok" || r="sudo_privs.txt not found"
check "sudo_privs.txt exists" "$r"

if [[ -f ~/seclab/sudo_privs.txt ]]; then
  lines=$(wc -l < ~/seclab/sudo_privs.txt)
  [[ $lines -ge 1 ]] && r="ok" || r="sudo_privs.txt is empty"
  check "sudo_privs.txt has content" "$r"
fi

[[ -f ~/seclab/sudoers.txt ]] && r="ok" || r="sudoers.txt not found"
check "sudoers.txt exists" "$r"

if [[ -f ~/seclab/sudoers.txt ]]; then
  grep -q "root\|ALL\|Defaults" ~/seclab/sudoers.txt && r="ok" || r="sudoers.txt doesn't look like sudoers content"
  check "sudoers.txt has sudoers content" "$r"
fi

[[ -f ~/seclab/sudoers_d.txt ]] && r="ok" || r="sudoers_d.txt not found"
check "sudoers_d.txt exists" "$r"

# Task 3
[[ -f ~/seclab/pam_sudo.txt ]] && r="ok" || r="pam_sudo.txt not found"
check "pam_sudo.txt exists" "$r"

if [[ -f ~/seclab/pam_sudo.txt ]]; then
  grep -q "pam_\|@include\|auth\|session" ~/seclab/pam_sudo.txt && r="ok" || r="pam_sudo.txt doesn't look like a PAM config"
  check "pam_sudo.txt looks like PAM config" "$r"
fi

[[ -f ~/seclab/pam_login.txt ]] && r="ok" || r="pam_login.txt not found"
check "pam_login.txt exists" "$r"

[[ -f ~/seclab/pam_configs.txt ]] && r="ok" || r="pam_configs.txt not found"
check "pam_configs.txt exists" "$r"

if [[ -f ~/seclab/pam_configs.txt ]]; then
  grep -q "sudo\|login\|ssh\|common" ~/seclab/pam_configs.txt && r="ok" || r="pam_configs.txt doesn't list expected PAM config files"
  check "pam_configs.txt lists PAM services" "$r"
fi

# Task 4
[[ -f ~/seclab/ufw_status.txt ]] && r="ok" || r="ufw_status.txt not found"
check "ufw_status.txt exists" "$r"

if [[ -f ~/seclab/ufw_status.txt ]]; then
  grep -qi "status\|active\|inactive\|disabled" ~/seclab/ufw_status.txt && r="ok" || r="ufw_status.txt doesn't look like ufw output"
  check "ufw_status.txt contains ufw status" "$r"
fi

[[ -f ~/seclab/listening_services.txt ]] && r="ok" || r="listening_services.txt not found"
check "listening_services.txt exists" "$r"

[[ -f ~/seclab/world_writable.txt ]] && r="ok" || r="world_writable.txt not found (should exist even if empty)"
check "world_writable.txt exists" "$r"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
