# NFS — Network File System

## Overview

NFS (Network File System) allows a server to export a directory over the network so that clients can mount it as if it were a local filesystem. First developed by Sun Microsystems in 1984, NFS remains a cornerstone of shared storage in Linux environments: HPC clusters, media servers, CI/CD artifact stores, and legacy enterprise NAS systems all rely on it.

Understanding NFS matters for SREs because:
- NFS issues cause subtle, hard-to-diagnose failures — processes hang, logs fill, disk space appears full when it is not
- Many legacy applications still depend on NFS-mounted configuration directories
- Kubernetes PersistentVolumes frequently back onto NFS
- Diagnosing NFS problems requires knowing the RPC layer underneath

---

## NFS Protocol Versions

### NFSv3

- **Stateless**: each request carries all information needed to process it
- Uses **UDP or TCP** (TCP strongly preferred for reliability)
- Uses **RPC portmapper** (`rpcbind`) for service discovery
- Locking handled by separate `lockd` / `statd` daemons
- Still very common; simpler to configure; doesn't require Kerberos

### NFSv4

- **Stateful**: server maintains per-client state (open files, locks, delegations)
- **TCP only** — uses a single well-known port **2049** (no portmapper needed for basic operation)
- Integrated locking protocol (no separate `lockd`)
- Optional Kerberos security (sec=krb5, krb5i, krb5p)
- Supports **delegations**: server grants client exclusive read/write caching rights
- ACL support (NFSv4 ACLs, not just POSIX mode bits)
- **Recommended for new deployments**

### NFSv4.1 / NFSv4.2

- NFSv4.1: parallel NFS (pNFS) for direct-to-storage access, sessions
- NFSv4.2: server-side copy, sparse file support, application I/O advise

---

## The RPC Layer

NFS is built on **ONC RPC** (Open Network Computing Remote Procedure Call). Each NFS sub-service (mount, NFS proper, lock, status) registers itself with `rpcbind` (formerly `portmapper`).

```
Client                               Server
  │                                    │
  │── connect to port 111 (rpcbind) ──▶│  "what port is NFS on?"
  │◀─ port 2049 for NFS ──────────────│
  │── NFS requests to port 2049 ──────▶│
```

With NFSv4, the client talks directly to port 2049 — no portmapper needed for the main NFS protocol, though `rpcbind` is still required for NFSv3 sub-services.

---

## Server-Side Setup (Reference)

You will typically be the NFS *client* in production; the server is set up by a storage team. But you should understand the server side for lab work and postmortems.

### Server packages (Ubuntu)

```bash
apt-get install -y nfs-kernel-server
```

### Exports file `/etc/exports`

```
# Syntax: path  client(options)
/data/shared    192.168.1.0/24(rw,sync,no_subtree_check)
/data/readonly  *(ro,sync,no_subtree_check)
/home           10.0.0.0/8(rw,sync,root_squash,no_subtree_check)
```

**Key export options:**

| Option | Meaning |
|--------|---------|
| `rw` | Read-write access |
| `ro` | Read-only |
| `sync` | Write to disk before replying (safe, slower) |
| `async` | Reply before disk write (fast, data loss on crash) |
| `root_squash` | Map root (uid=0) to `nobody` (default, safer) |
| `no_root_squash` | Allow root on client to act as root on server |
| `no_subtree_check` | Don't verify file is in exported subtree (recommended) |
| `fsid=0` | Required for NFSv4 root export |

```bash
# Apply export changes without restart
exportfs -ra
exportfs -v      # show active exports
```

---

## Client-Side Mounting

### Ad-hoc mount

```bash
# Install client tools
apt-get install -y nfs-common

# Mount NFSv4
mount -t nfs4 server:/export/path /mnt/nfs

# Mount NFSv3
mount -t nfs -o vers=3 server:/export/path /mnt/nfs

# With explicit options
mount -t nfs -o vers=4,rsize=1048576,wsize=1048576,hard,timeo=600 \
  server:/export/path /mnt/nfs
```

### /etc/fstab Entry

```
server:/export/path   /mnt/nfs   nfs4   rsize=1048576,wsize=1048576,hard,timeo=600,retrans=5,_netdev   0 0
```

The `_netdev` option tells the init system to mount this after the network is up.

---

## Mount Options Explained

### Performance Options

| Option | Default | Recommendation |
|--------|---------|----------------|
| `rsize=N` | 131072 | 1048576 (1 MiB) for fast networks |
| `wsize=N` | 131072 | 1048576 (1 MiB) for fast networks |
| `noatime` | — | Add for read-heavy workloads (avoids atime writes) |
| `nodiratime` | — | Skip atime updates for directories |

`rsize` and `wsize` control the maximum read/write block size. Larger values reduce round-trips on fast networks.

### Reliability Options

| Option | Meaning |
|--------|---------|
| `hard` | Retry NFS operations indefinitely if server unreachable (default) |
| `soft` | Return an error after `retrans` retries — can cause data corruption |
| `timeo=N` | Timeout in tenths of a second before retransmit (default 600 = 60s) |
| `retrans=N` | Number of retransmissions before `soft` mounts give up (default 3) |
| `intr` | Allow signals to interrupt hung NFS calls (kernel < 2.6.25) |

**Rule of thumb:** Always use `hard` mounts unless you explicitly accept the risk of data corruption. Use `soft` only for read-only or non-critical data where hanging is worse than corruption.

### Security Options

| Option | Meaning |
|--------|---------|
| `sec=sys` | Default Unix UID/GID mapping |
| `sec=krb5` | Kerberos authentication only |
| `sec=krb5i` | Kerberos auth + integrity checking |
| `sec=krb5p` | Kerberos auth + encryption |

---

## Key Client Tools

### showmount

Queries an NFS server for its exports.

```bash
# Show exports from a server
showmount -e nfsserver.example.com

# Show which clients have mounted what
showmount -a nfsserver.example.com

# Show exported directories only
showmount -d nfsserver.example.com
```

### rpcinfo

Queries `rpcbind` to list registered RPC programs.

```bash
# Show all registered RPC programs on localhost
rpcinfo -p localhost

# Show programs on a remote host
rpcinfo -p nfsserver.example.com

# Check if portmapper is reachable on a host
rpcinfo -T tcp nfsserver.example.com 100000
```

Output columns: `program  version  proto  port  service`

Key programs to look for:

| Program | Number | Service |
|---------|--------|---------|
| 100000  | portmapper | rpcbind |
| 100003  | nfs | NFS server |
| 100005  | mountd | mount daemon |
| 100021  | nlockmgr | network lock manager |
| 100024  | status | status monitor (statd) |

### nfsstat

Displays NFS statistics from `/proc/net/rpc/`.

```bash
# Show all NFS statistics (client + server)
nfsstat

# Client statistics only
nfsstat -c

# Server statistics only
nfsstat -s

# Show NFS v3 stats
nfsstat -3

# Show NFS v4 stats
nfsstat -4

# Continuous update (like vmstat)
nfsstat -c 5    # every 5 seconds
```

Understanding nfsstat output:

```
Client rpc stats:
calls      retrans    authrefrsh
1234       0          1234

Client nfs v3:
null       getattr    setattr    lookup     access    ...
0    0%    523  42%   ...
```

The `retrans` counter is critical — a non-zero value means the network or server is struggling.

---

## Common NFS Issues

### Stale File Handle

```
ls: cannot access '/mnt/nfs/file': Stale file handle
```

The file or directory was removed on the server while you had it open. Unmount and remount the filesystem.

```bash
umount -l /mnt/nfs    # lazy unmount
mount /mnt/nfs
```

### Mount Hangs

A `hard` mount to an unreachable server will block indefinitely. The process waiting on NFS will appear in `D` state (uninterruptible sleep) in `ps`:

```bash
ps aux | grep 'D '
```

To diagnose: check if the server is reachable, check `rpcinfo`, check `nfsstat` retrans count.

### Permission Denied Despite Correct Mode Bits

NFS uses the client's UID/GID. If the server has `root_squash` enabled, root on the client is mapped to `nobody`. Ensure user UIDs match between client and server, or use NFSv4 with Kerberos.

### Timeout Tuning

If your NFS server is across a high-latency WAN link:

```bash
mount -t nfs -o timeo=300,retrans=10,rsize=32768,wsize=32768 \
  server:/export /mnt/nfs
```

---

## Autofs

`autofs` mounts NFS filesystems on-demand and unmounts them after an idle timeout. This avoids boot-time failures if NFS servers are temporarily unreachable.

```bash
apt-get install -y autofs

# /etc/auto.master — master map
/mnt/auto  /etc/auto.nfs  --timeout=300

# /etc/auto.nfs — sub-map
data    -rw,hard,intr   nfsserver:/exports/data
homes   -rw,hard,intr   nfsserver:/exports/homes
```

```bash
systemctl restart autofs
ls /mnt/auto/data    # triggers mount on first access
```

---

## Diagnosing NFS Health

Systematic approach for an NFS issue:

```bash
# 1. Is the NFS server reachable?
ping -c 3 nfsserver

# 2. Is rpcbind running on the server?
rpcinfo -p nfsserver 2>&1

# 3. Is NFS exported?
showmount -e nfsserver

# 4. Is nfs-common installed on client?
dpkg -l nfs-common

# 5. Are there active mounts?
mount | grep nfs
cat /proc/mounts | grep nfs

# 6. Check client NFS stats for retransmits
nfsstat -c | grep retrans

# 7. Check dmesg for NFS errors
dmesg | grep -i nfs

# 8. Check for hung processes
ps aux | awk '$8 == "D"'
```

---

## Viewing NFS Mounts in /proc

```bash
# Active mounts with options
cat /proc/mounts | grep nfs

# NFS client statistics
cat /proc/net/rpc/nfs

# NFSv4 client state
cat /proc/net/rpc/nfs4.callback/channel | head -5  # if mounted
```

---

## Sample /etc/fstab NFS Entry

Full production-grade entry:

```
# NFS mount: shared data volume
# Options:
#   nfs4         - use NFSv4 protocol
#   rsize/wsize  - 1 MiB block size for throughput
#   hard         - retry indefinitely (data integrity)
#   timeo=600    - 60 second timeout before retry
#   retrans=5    - retry 5 times before error (soft only)
#   noatime      - don't update access time (performance)
#   _netdev      - wait for network before mounting

nfsserver.example.com:/exports/data  /mnt/data  nfs4  rsize=1048576,wsize=1048576,hard,timeo=600,retrans=5,noatime,_netdev  0  0
```

---

## Quick Reference

```bash
# Install client tools
apt-get install -y nfs-common

# Check exports on server
showmount -e SERVER

# Query RPC services
rpcinfo -p SERVER

# Mount manually
mount -t nfs4 SERVER:/path /mnt/point

# View NFS stats
nfsstat -c

# Check active mounts
mount | grep nfs

# Lazy unmount (for stale file handles)
umount -l /mnt/nfs
```

## Further Reading

- [nfs(5) man page](https://man7.org/linux/man-pages/man5/nfs.5.html) — Definitive reference for all NFS mount options (`hard`/`soft`, `rsize`, `wsize`, `timeo`, `retrans`, `sec`) with trade-off explanations matching the mount options table in this lesson.
- [NFS HOWTO](https://nfs.sourceforge.net/nfs-howto/) — Comprehensive guide to setting up NFS servers and clients on Linux, covering version selection, Kerberos security, and autofs configuration.
- [exports(5) man page](https://man7.org/linux/man-pages/man5/exports.5.html) — Documents every server-side export option (`root_squash`, `sync`, `async`, `no_subtree_check`, `fsid`) used in the `/etc/exports` section of this lesson.
- [Arch Wiki: NFS](https://wiki.archlinux.org/title/NFS) — Practical setup guide for NFSv3 and NFSv4 covering firewall rules, autofs, and common troubleshooting steps for stale file handles and mount hangs.
- [RFC 7530 — NFS Version 4](https://datatracker.ietf.org/doc/html/rfc7530) — The NFSv4 protocol specification defining the stateful session model, integrated locking, delegations, and ACL support that distinguish NFSv4 from NFSv3.
