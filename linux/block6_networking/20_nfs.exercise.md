# Exercise: NFS — Network File System

These exercises focus on the NFS *client* toolset. Since we don't have an actual NFS server in the container, we'll focus on installing and using the diagnostic tools, understanding the RPC layer, and writing health check scripts.

---

## Setup

```bash
mkdir -p ~/practice/nfs
cd ~/practice/nfs
```

---

## Task 1 — Install nfs-common

Install the NFS client utilities package. This provides `mount.nfs`, `showmount`, `nfsstat`, and the RPC tooling.

```bash
apt-get update -q && apt-get install -y nfs-common

# Verify installation
dpkg -l nfs-common
dpkg -l | grep nfs-common

# Check what binaries were installed
dpkg -L nfs-common | grep /usr/sbin
dpkg -L nfs-common | grep /sbin
```

---

## Task 2 — Explore Available Tools

Check which tools are now available and their basic usage:

```bash
# Check for key tools
for cmd in showmount rpcinfo nfsstat mount.nfs; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "FOUND: $cmd at $(command -v $cmd)"
    else
        # Try common paths
        for p in /sbin /usr/sbin /bin /usr/bin; do
            [ -x "$p/$cmd" ] && echo "FOUND: $p/$cmd" && break
        done
    fi
done

# Show nfsstat help
nfsstat --help 2>&1 | head -20 || true

# Show rpcinfo help
rpcinfo --help 2>&1 | head -20 || true
```

---

## Task 3 — Check rpcbind / portmapper

`rpcbind` is the portmapper that NFS relies on for service discovery.

```bash
# Check if rpcbind package is available
apt-get install -y rpcbind 2>&1 | tail -5

# Check if rpcbind is running
if systemctl is-active rpcbind 2>/dev/null; then
    echo "rpcbind is running"
else
    echo "rpcbind is not running (may be in container)"
    # Try to start it
    rpcbind 2>/dev/null && echo "started rpcbind" || echo "could not start rpcbind"
fi

# Alternative: check if the process exists
ps aux | grep rpcbind | grep -v grep || echo "rpcbind process not found"
```

---

## Task 4 — rpcinfo Output

Query the local RPC registry:

```bash
# Show all registered RPC programs on localhost
rpcinfo -p localhost 2>&1 || rpcinfo -p 127.0.0.1 2>&1 || echo "rpcbind not running"

# If rpcbind is running, grep for NFS-related programs
rpcinfo -p localhost 2>/dev/null | grep -E '(100003|100005|100021|100024|mountd|nfs|lock|status)' \
  || echo "No NFS programs registered (expected without NFS server)"

# The portmapper itself:
rpcinfo -p localhost 2>/dev/null | grep 100000 | head -5 \
  || echo "rpcbind not answering"
```

Document what you see:

```bash
# Save rpcinfo output for reference
rpcinfo -p localhost > ~/practice/nfs/rpcinfo_output.txt 2>&1
cat ~/practice/nfs/rpcinfo_output.txt
```

---

## Task 5 — nfsstat Output

`nfsstat` reads from `/proc/net/rpc/`. Even without active mounts, you can inspect the counters.

```bash
# View all NFS stats
nfsstat 2>&1 | head -40

# Client stats only
nfsstat -c 2>&1

# Check if the proc files exist
ls -la /proc/net/rpc/ 2>/dev/null || echo "/proc/net/rpc not available in this kernel"

# Check for NFS modules
cat /proc/net/rpc/nfs 2>/dev/null || echo "NFS proc entry not available"
```

---

## Task 6 — Write an NFS Health Check Script

Write a reusable script that checks NFS client readiness:

```bash
cat > ~/practice/nfs/nfs_health_check.sh << 'EOF'
#!/bin/bash
# nfs_health_check.sh — checks NFS client tooling and connectivity

PASS=0
FAIL=0
WARN=0

ok()   { echo "  OK   $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL $1"; FAIL=$((FAIL+1)); }
warn() { echo "  WARN $1"; WARN=$((WARN+1)); }

echo "=== NFS Client Health Check ==="
echo ""

# Check nfs-common is installed
echo "[1] nfs-common package"
if dpkg -l nfs-common 2>/dev/null | grep -q '^ii'; then
    ok "nfs-common is installed"
else
    fail "nfs-common is NOT installed"
fi

# Check key binaries
echo ""
echo "[2] Required binaries"
for cmd in showmount rpcinfo nfsstat; do
    if command -v "$cmd" >/dev/null 2>&1 || \
       [ -x "/sbin/$cmd" ] || [ -x "/usr/sbin/$cmd" ]; then
        ok "$cmd is available"
    else
        fail "$cmd not found"
    fi
done

# Check rpcbind service
echo ""
echo "[3] rpcbind service"
if pgrep -x rpcbind >/dev/null 2>&1; then
    ok "rpcbind process is running"
elif rpcinfo -p localhost >/dev/null 2>&1; then
    ok "rpcbind is responding"
else
    warn "rpcbind is not running (NFS mounts will fail)"
fi

# Check for active NFS mounts
echo ""
echo "[4] Active NFS mounts"
NFS_MOUNTS=$(mount | grep -c ' type nfs' 2>/dev/null || echo 0)
if [ "$NFS_MOUNTS" -gt 0 ]; then
    ok "$NFS_MOUNTS active NFS mount(s) found"
    mount | grep ' type nfs'
else
    warn "No active NFS mounts"
fi

# Check /proc/net/rpc/nfs
echo ""
echo "[5] Kernel NFS stats"
if [ -r /proc/net/rpc/nfs ]; then
    ok "/proc/net/rpc/nfs is readable"
    # Check for retransmits (column 3 in 'net' line)
    RETRANS=$(awk '/^net/{print $3}' /proc/net/rpc/nfs 2>/dev/null || echo 0)
    if [ "${RETRANS:-0}" -gt 0 ]; then
        warn "NFS retransmits detected: $RETRANS (network or server issues)"
    else
        ok "No NFS retransmits"
    fi
else
    warn "/proc/net/rpc/nfs not available"
fi

echo ""
echo "=== Summary: $PASS OK, $WARN warnings, $FAIL failures ==="
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
EOF

chmod +x ~/practice/nfs/nfs_health_check.sh
bash ~/practice/nfs/nfs_health_check.sh
```

---

## Task 7 — Write a Sample /etc/fstab NFS Entry

Create a reference fstab entry file (we won't actually mount — just document the correct format):

```bash
cat > ~/practice/nfs/sample_fstab_entry.txt << 'EOF'
# ======================================================
# Sample NFS /etc/fstab entries
# ======================================================

# NFSv4 mount with performance and reliability options
# Format: <server>:<export>  <mountpoint>  <type>  <options>  <dump>  <pass>

# High-throughput data share (1 MiB block size, hard mount)
nfsserver.example.com:/exports/data  /mnt/data  nfs4  rsize=1048576,wsize=1048576,hard,timeo=600,retrans=5,noatime,_netdev  0  0

# Read-only software repository (smaller blocks, soft is OK for read-only)
nfsserver.example.com:/exports/software  /mnt/software  nfs4  ro,rsize=32768,soft,timeo=300,_netdev  0  0

# Home directories (NFSv3 with security options)
nfsserver.example.com:/home  /home/nfs  nfs  vers=3,rsize=32768,wsize=32768,hard,timeo=600,sec=sys,_netdev  0  0

# Autofs-managed (no fstab entry — managed by /etc/auto.master instead)
# /mnt/auto  /etc/auto.nfs  --timeout=300

# ======================================================
# Option Reference
# ======================================================
# rsize/wsize   : read/write block size in bytes (use 1048576 for 10GbE+)
# hard          : retry indefinitely (required for data integrity)
# soft          : give up after retrans attempts (risk of data corruption)
# timeo=600     : 60 second timeout before retry (tenths of a second)
# retrans=5     : retry count (used only with soft)
# noatime       : skip access time updates (reduces write load)
# _netdev       : wait for network before mounting at boot
# sec=sys       : Unix UID/GID auth (default)
# sec=krb5      : Kerberos auth
# vers=3/4      : force NFSv3 or NFSv4
EOF

cat ~/practice/nfs/sample_fstab_entry.txt
```

---

## Task 8 — Inspect /proc/mounts for NFS Info

Even without active NFS mounts, understand what to look for:

```bash
# Show all current mounts
cat /proc/mounts

# How to find NFS mounts
grep nfs /proc/mounts || echo "No NFS mounts active"

# Parse mount options for an NFS mount (simulation)
echo "nfsserver:/data /mnt nfs4 rsize=1048576,wsize=1048576,hard,timeo=600 0 0" | \
  awk '{split($4,a,","); print "Mount options:"; for(i in a) print "  " a[i]}'
```

---

## Verification

```bash
# Check all practice files exist
ls -la ~/practice/nfs/

# Run health check one more time
bash ~/practice/nfs/nfs_health_check.sh

# Verify nfs-common is installed
dpkg -l nfs-common | grep '^ii'

# Check tools are accessible
which showmount rpcinfo nfsstat
```
