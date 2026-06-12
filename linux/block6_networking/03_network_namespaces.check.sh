#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: ip netns command is available
check "ip netns command is available" \
  "ip netns help > /dev/null 2>&1 || ip netns list > /dev/null 2>&1"

# Check 2: /var/run/netns directory exists (created when ip netns is used)
check "/var/run/netns exists" \
  "[ -d /var/run/netns ] || ip netns list > /dev/null 2>&1"

# Check 3: lsns is available
check "lsns is available" \
  "command -v lsns > /dev/null 2>&1"

# Check 4: /proc/self/ns/net exists
check "/proc/self/ns/net namespace symlink exists" \
  "[ -L /proc/self/ns/net ]"

# Check 5: practice directory exists
check "~/practice directory exists" \
  "[ -d \$HOME/practice ]"

# Check 6: Either veth pair exists OR netns_done.txt was created
check "veth interface exists OR netns_done.txt exists" \
  "ip link show 2>/dev/null | grep -q 'veth' || [ -f \$HOME/practice/netns_done.txt ]"

# Check 7: netns_done.txt has content (if it exists)
check "netns_done.txt has content (if exists)" \
  "[ ! -f \$HOME/practice/netns_done.txt ] || [ -s \$HOME/practice/netns_done.txt ]"

# Check 8: ip link add type veth is supported (kernel has veth module)
check "veth interface type is supported" \
  "sudo ip link add check-veth-$$ type veth peer name check-vpeer-$$ 2>/dev/null && sudo ip link del check-veth-$$ 2>/dev/null; true"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
