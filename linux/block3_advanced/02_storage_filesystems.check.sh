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

[[ -d ~/storagelab ]] && r="ok" || r="~/storagelab not found"
check "~/storagelab exists" "$r"

# Task 1
[[ -f ~/storagelab/filesystems.txt ]] && r="ok" || r="filesystems.txt not found"
check "filesystems.txt exists" "$r"

if [[ -f ~/storagelab/filesystems.txt ]]; then
  grep -q "Filesystem\|/" ~/storagelab/filesystems.txt && r="ok" || r="filesystems.txt doesn't look like df output"
  check "filesystems.txt looks like df -hT output" "$r"
fi

[[ -f ~/storagelab/block_devices.txt ]] && r="ok" || r="block_devices.txt not found"
check "block_devices.txt exists" "$r"

[[ -f ~/storagelab/fstab.txt ]] && r="ok" || r="fstab.txt not found"
check "fstab.txt exists" "$r"

if [[ -f ~/storagelab/fstab.txt ]]; then
  lines=$(wc -l < ~/storagelab/fstab.txt)
  [[ $lines -ge 1 ]] && r="ok" || r="fstab.txt is empty"
  check "fstab.txt has content" "$r"
fi

# Task 2
[[ -f ~/storagelab/mounts.txt ]] && r="ok" || r="mounts.txt not found"
check "mounts.txt exists" "$r"

[[ -f ~/storagelab/mountpoints.txt ]] && r="ok" || r="mountpoints.txt not found"
check "mountpoints.txt exists" "$r"

if [[ -f ~/storagelab/mountpoints.txt ]]; then
  grep -q "/" ~/storagelab/mountpoints.txt && r="ok" || r="mountpoints.txt doesn't contain paths"
  check "mountpoints.txt contains paths" "$r"
fi

# Task 3: inodes
[[ -f ~/storagelab/inodes.txt ]] && r="ok" || r="inodes.txt not found"
check "inodes.txt exists" "$r"

if [[ -f ~/storagelab/inodes.txt ]]; then
  grep -q "Inodes\|IUsed\|IFree" ~/storagelab/inodes.txt && r="ok" || r="inodes.txt doesn't look like df -i output"
  check "inodes.txt looks like df -i output" "$r"
fi

for f in a.txt b.txt c.txt a_hardlink.txt; do
  [[ -f ~/storagelab/$f ]] && r="ok" || r="$f not found in ~/storagelab/"
  check "$f exists" "$r"
done

# Check hard link: same inode
if [[ -f ~/storagelab/a.txt && -f ~/storagelab/a_hardlink.txt ]]; then
  inode1=$(stat -c %i ~/storagelab/a.txt)
  inode2=$(stat -c %i ~/storagelab/a_hardlink.txt)
  [[ "$inode1" == "$inode2" ]] && r="ok" || r="a.txt (inode $inode1) and a_hardlink.txt (inode $inode2) have different inodes — hard link not created correctly"
  check "a.txt and a_hardlink.txt share the same inode" "$r"
fi

[[ -f ~/storagelab/inode_listing.txt ]] && r="ok" || r="inode_listing.txt not found"
check "inode_listing.txt exists" "$r"

# Task 4
[[ -f ~/storagelab/dir_usage.txt ]] && r="ok" || r="dir_usage.txt not found"
check "dir_usage.txt exists" "$r"

[[ -f ~/storagelab/largest_lib_files.txt ]] && r="ok" || r="largest_lib_files.txt not found"
check "largest_lib_files.txt exists" "$r"

if [[ -f ~/storagelab/largest_lib_files.txt ]]; then
  lines=$(wc -l < ~/storagelab/largest_lib_files.txt)
  [[ $lines -ge 5 ]] && r="ok" || r="largest_lib_files.txt has only $lines lines (expected ~10)"
  check "largest_lib_files.txt has 5+ entries" "$r"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
