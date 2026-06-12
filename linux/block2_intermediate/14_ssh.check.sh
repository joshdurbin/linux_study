#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "test_ed25519 private key exists"    "[[ -f ~/practice/test_ed25519 ]]"
check "test_ed25519.pub public key exists" "[[ -f ~/practice/test_ed25519.pub ]]"
check "public key is ed25519 type"         "grep -q 'ssh-ed25519' ~/practice/test_ed25519.pub"
check "ssh_keygen.txt has fingerprint"     "grep -qE '(SHA256|MD5)' ~/practice/ssh_keygen.txt"

check "ssh_config exists"                  "[[ -f ~/practice/ssh_config ]]"
check "ssh_config has Host entries"        "grep -c '^Host ' ~/practice/ssh_config | grep -qvE '^0$'"
check "ssh_config has ProxyJump"           "grep -qi 'ProxyJump' ~/practice/ssh_config"
check "ssh_config has LocalForward"        "grep -qi 'LocalForward' ~/practice/ssh_config"

check "authorized_keys_examples.txt exists" "[[ -f ~/practice/authorized_keys_examples.txt ]]"
check "authorized_keys_examples.txt has from= key" "grep -q 'from=' ~/practice/authorized_keys_examples.txt"
check "authorized_keys_examples.txt has command= key" "grep -q 'command=' ~/practice/authorized_keys_examples.txt"

check "sshd_hardened.conf exists"          "[[ -f ~/practice/sshd_hardened.conf ]]"
check "sshd_hardened.conf has PermitRootLogin no" "grep -qi 'PermitRootLogin.*no' ~/practice/sshd_hardened.conf"
check "sshd_hardened.conf has PasswordAuthentication no" "grep -qi 'PasswordAuthentication.*no' ~/practice/sshd_hardened.conf"

check "ssh_tunnels.txt exists"             "[[ -f ~/practice/ssh_tunnels.txt ]]"
check "ssh_tunnels.txt has LocalForward"   "grep -qiE '(\-L|LocalForward)' ~/practice/ssh_tunnels.txt"
check "ssh_tunnels.txt has SOCKS proxy"    "grep -qiE '(\-D|SOCKS|socks)' ~/practice/ssh_tunnels.txt"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
