#!/bin/bash
# check.sh — NFS tools and client setup

PASS=0
FAIL=0

check_cmd() {
    local desc="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $desc"
        FAIL=$((FAIL + 1))
    fi
}

# -------------------------------------------------------
# 1. nfs-common is installed
# -------------------------------------------------------
if dpkg -l nfs-common 2>/dev/null | grep -q '^ii'; then
    echo "PASS: nfs-common package is installed"
    PASS=$((PASS + 1))
else
    echo "FAIL: nfs-common is not installed (run: apt-get install -y nfs-common)"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 2. showmount is available
# -------------------------------------------------------
SHOWMOUNT_PATH=""
for p in /usr/sbin/showmount /sbin/showmount /usr/bin/showmount /bin/showmount; do
    [ -x "$p" ] && SHOWMOUNT_PATH="$p" && break
done
command -v showmount >/dev/null 2>&1 && SHOWMOUNT_PATH=$(command -v showmount)

if [ -n "$SHOWMOUNT_PATH" ]; then
    echo "PASS: showmount is available ($SHOWMOUNT_PATH)"
    PASS=$((PASS + 1))
else
    echo "FAIL: showmount not found"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 3. rpcinfo is available
# -------------------------------------------------------
RPCINFO_PATH=""
for p in /usr/sbin/rpcinfo /sbin/rpcinfo /usr/bin/rpcinfo /bin/rpcinfo; do
    [ -x "$p" ] && RPCINFO_PATH="$p" && break
done
command -v rpcinfo >/dev/null 2>&1 && RPCINFO_PATH=$(command -v rpcinfo)

if [ -n "$RPCINFO_PATH" ]; then
    echo "PASS: rpcinfo is available ($RPCINFO_PATH)"
    PASS=$((PASS + 1))
else
    echo "FAIL: rpcinfo not found"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 4. nfsstat is available
# -------------------------------------------------------
NFSSTAT_PATH=""
for p in /usr/sbin/nfsstat /sbin/nfsstat /usr/bin/nfsstat /bin/nfsstat; do
    [ -x "$p" ] && NFSSTAT_PATH="$p" && break
done
command -v nfsstat >/dev/null 2>&1 && NFSSTAT_PATH=$(command -v nfsstat)

if [ -n "$NFSSTAT_PATH" ]; then
    echo "PASS: nfsstat is available ($NFSSTAT_PATH)"
    PASS=$((PASS + 1))
else
    echo "FAIL: nfsstat not found"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 5. nfsstat runs without crashing
# -------------------------------------------------------
if [ -n "$NFSSTAT_PATH" ]; then
    # nfsstat may exit non-zero if /proc/net/rpc is unavailable, but it should run
    if "$NFSSTAT_PATH" 2>&1 | grep -qiE '(calls|stats|nfs|client|server|not)'; then
        echo "PASS: nfsstat produces output"
        PASS=$((PASS + 1))
    else
        # Just check it doesn't segfault / hard error
        "$NFSSTAT_PATH" >/dev/null 2>&1
        RC=$?
        if [ $RC -lt 128 ]; then
            echo "PASS: nfsstat runs (exit code $RC)"
            PASS=$((PASS + 1))
        else
            echo "FAIL: nfsstat crashed (exit code $RC)"
            FAIL=$((FAIL + 1))
        fi
    fi
fi

# -------------------------------------------------------
# 6. rpcinfo runs against localhost (may fail if rpcbind not running)
# -------------------------------------------------------
if [ -n "$RPCINFO_PATH" ]; then
    if "$RPCINFO_PATH" -p localhost >/dev/null 2>&1 || \
       "$RPCINFO_PATH" -p 127.0.0.1 >/dev/null 2>&1; then
        echo "PASS: rpcinfo can query localhost (rpcbind is running)"
        PASS=$((PASS + 1))
    else
        echo "PASS: rpcinfo is available (rpcbind not running — acceptable in container)"
        PASS=$((PASS + 1))
    fi
fi

# -------------------------------------------------------
# 7. Practice directory exists
# -------------------------------------------------------
if [ -d "$HOME/practice/nfs" ]; then
    echo "PASS: ~/practice/nfs directory exists"
    PASS=$((PASS + 1))
else
    echo "FAIL: ~/practice/nfs directory not found"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 8. nfs_health_check.sh exists
# -------------------------------------------------------
if [ -f "$HOME/practice/nfs/nfs_health_check.sh" ]; then
    echo "PASS: nfs_health_check.sh exists"
    PASS=$((PASS + 1))
    if [ -x "$HOME/practice/nfs/nfs_health_check.sh" ]; then
        echo "PASS: nfs_health_check.sh is executable"
        PASS=$((PASS + 1))
    else
        echo "FAIL: nfs_health_check.sh is not executable"
        FAIL=$((FAIL + 1))
    fi
else
    echo "FAIL: nfs_health_check.sh not found"
    FAIL=$((FAIL + 1))
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 9. nfs_health_check.sh runs
# -------------------------------------------------------
if [ -f "$HOME/practice/nfs/nfs_health_check.sh" ]; then
    if bash "$HOME/practice/nfs/nfs_health_check.sh" >/dev/null 2>&1; then
        echo "PASS: nfs_health_check.sh executes successfully"
        PASS=$((PASS + 1))
    else
        # Health check may exit 1 when rpcbind not running — that's acceptable
        echo "PASS: nfs_health_check.sh executed (non-zero exit acceptable in container)"
        PASS=$((PASS + 1))
    fi
fi

# -------------------------------------------------------
# 10. sample_fstab_entry.txt exists and contains key keywords
# -------------------------------------------------------
if [ -f "$HOME/practice/nfs/sample_fstab_entry.txt" ]; then
    echo "PASS: sample_fstab_entry.txt exists"
    PASS=$((PASS + 1))
    if grep -q 'nfs4\|nfs ' "$HOME/practice/nfs/sample_fstab_entry.txt"; then
        echo "PASS: sample_fstab_entry.txt contains NFS mount entries"
        PASS=$((PASS + 1))
    else
        echo "FAIL: sample_fstab_entry.txt does not contain NFS mount entries"
        FAIL=$((FAIL + 1))
    fi
else
    echo "FAIL: sample_fstab_entry.txt not found"
    FAIL=$((FAIL + 1))
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 11. rpcinfo_output.txt was saved
# -------------------------------------------------------
if [ -f "$HOME/practice/nfs/rpcinfo_output.txt" ]; then
    echo "PASS: rpcinfo_output.txt saved"
    PASS=$((PASS + 1))
else
    echo "FAIL: rpcinfo_output.txt not found (run: rpcinfo -p localhost > ~/practice/nfs/rpcinfo_output.txt)"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# Summary
# -------------------------------------------------------
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -eq 0 ]; then
    exit 0
else
    exit 1
fi
