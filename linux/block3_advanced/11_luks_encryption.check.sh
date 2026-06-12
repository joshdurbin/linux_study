#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: cryptsetup is available
check "cryptsetup is available" \
  "command -v cryptsetup > /dev/null 2>&1"

# Check 2: practice/luks directory exists
check "~/practice/luks directory exists" \
  "[ -d \$HOME/practice/luks ]"

# Check 3: container.img was created
check "container.img exists" \
  "[ -f \$HOME/practice/luks/container.img ]"

# Check 4: container.img is >= 50MB
check "container.img is at least 50MB" \
  "[ \"\$(stat -c%s \$HOME/practice/luks/container.img 2>/dev/null || echo 0)\" -ge 52428800 ]"

# Check 5: container.img is LUKS formatted
check "container.img is LUKS formatted" \
  "sudo cryptsetup isLuks \$HOME/practice/luks/container.img 2>/dev/null"

# Check 6: LUKS dump shows expected fields
check "container.img LUKS header contains cipher field" \
  "sudo cryptsetup luksDump \$HOME/practice/luks/container.img 2>/dev/null | grep -qi 'cipher'"

# Check 7: LUKS magic bytes present in raw file
check "container.img starts with LUKS magic bytes" \
  "sudo dd if=\$HOME/practice/luks/container.img bs=4 count=1 2>/dev/null | grep -qi 'LUKS' || \
   sudo dd if=\$HOME/practice/luks/container.img bs=4 count=1 2>/dev/null | xxd | grep -q '4c554b53'"

# Check 8: luks_status.sh exists and runs
check "luks_status.sh exists and runs" \
  "[ -f \$HOME/practice/luks/luks_status.sh ] && \
   bash \$HOME/practice/luks/luks_status.sh > /dev/null 2>&1"

# Check 9: luks_status.sh references cryptsetup
check "luks_status.sh uses cryptsetup" \
  "grep -q 'cryptsetup' \$HOME/practice/luks/luks_status.sh"

# Check 10: dm-crypt kernel module or device mapper is available
check "dm-crypt support is available (device-mapper)" \
  "[ -d /dev/mapper ] && ls /dev/mapper/ > /dev/null 2>&1"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
