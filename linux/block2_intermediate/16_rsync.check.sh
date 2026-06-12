#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

check "rsync is installed"                    "command -v rsync >/dev/null 2>&1"
check "rsync_src created"                     "[[ -d ~/practice/rsync_src ]]"
check "rsync_dst created"                     "[[ -d ~/practice/rsync_dst ]]"
check "rsync_dryrun.txt exists"               "[[ -f ~/practice/rsync_dryrun.txt ]]"
check "rsync_dryrun.txt shows file list"      "grep -q 'file' ~/practice/rsync_dryrun.txt"
check "rsync_result.txt shows sync happened"  "[[ -f ~/practice/rsync_result.txt ]]"
check "rsync_dst has file1.txt"               "[[ -f ~/practice/rsync_dst/file1.txt ]]"
check "rsync_dst has subdir"                  "[[ -d ~/practice/rsync_dst/subdir ]]"
check "rsync_incremental.txt exists"          "[[ -f ~/practice/rsync_incremental.txt ]]"
check "rsync_delete.txt exists"               "[[ -f ~/practice/rsync_delete.txt ]]"
check "file2.txt removed by --delete"         "[[ ! -f ~/practice/rsync_dst/file2.txt ]]"
check "rsync_exclude.txt exists"              "[[ -f ~/practice/rsync_exclude.txt ]]"
check ".env excluded from sync"               "[[ ! -f ~/practice/rsync_excl_dst/.env ]]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
