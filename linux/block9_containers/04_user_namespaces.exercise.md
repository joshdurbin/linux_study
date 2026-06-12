# Exercise: User Namespaces

Complete the following tasks. Save your notes to `~/practice/user_ns_notes.txt`.

## Task 1 — Document UID Mapping Concepts

```bash
mkdir -p ~/practice
cat > ~/practice/user_ns_notes.txt << 'EOF'
User Namespace Notes
=====================
User namespaces map UIDs/GIDs inside namespace to different IDs on the host.
Most common use: map host non-root user to UID 0 (root) inside namespace.
This is the basis for rootless containers.

Creating a user namespace:
  unshare --user --map-root-user /bin/bash
  Inside: id shows uid=0(root), but on host the process runs as your real UID.

UID/GID map files:
  /proc/self/uid_map  — format: <ns-uid> <host-uid> <count>
  /proc/self/gid_map  — same format for GIDs
  Example: "0  1000  1" means ns UID 0 = host UID 1000

Sub-UID ranges for rootless containers:
  /etc/subuid  — e.g., student:100000:65536
  /etc/subgid  — same for GIDs
  Tools: newuidmap, newgidmap
EOF
```

## Task 2 — Record Your Current UID Map

```bash
echo "" >> ~/practice/user_ns_notes.txt
echo "Current UID map:" >> ~/practice/user_ns_notes.txt
cat /proc/self/uid_map >> ~/practice/user_ns_notes.txt
echo "Current GID map:" >> ~/practice/user_ns_notes.txt
cat /proc/self/gid_map >> ~/practice/user_ns_notes.txt
```

## Task 3 — Check Sub-UID Configuration

```bash
echo "" >> ~/practice/user_ns_notes.txt
echo "Sub-UID entries for current user:" >> ~/practice/user_ns_notes.txt
grep "$(whoami)" /etc/subuid 2>/dev/null >> ~/practice/user_ns_notes.txt || echo "(no subuid entry found)" >> ~/practice/user_ns_notes.txt
grep "$(whoami)" /etc/subgid 2>/dev/null >> ~/practice/user_ns_notes.txt || echo "(no subgid entry found)" >> ~/practice/user_ns_notes.txt
```

## Task 4 — Record User Namespace Inode

```bash
echo "" >> ~/practice/user_ns_notes.txt
echo "Current user namespace inode:" >> ~/practice/user_ns_notes.txt
readlink /proc/self/ns/user >> ~/practice/user_ns_notes.txt
```

## Task 5 — Document Security Considerations

```bash
cat >> ~/practice/user_ns_notes.txt << 'EOF'

Security Implications
----------------------
User namespaces have been the source of multiple kernel CVEs:
  CVE-2022-0492: cgroup v1 release_agent escape
  CVE-2023-32233: nf_tables use-after-free reachable via user ns

Ubuntu restricts unprivileged user namespace creation:
  /proc/sys/kernel/unprivileged_userns_clone  (0=restricted, 1=allowed)
  /proc/sys/kernel/apparmor_restrict_unprivileged_userns (Ubuntu 23.10+)

Rootless container security model:
  - No setuid/setgid binaries needed for container creation
  - Kernel capabilities inside the namespace do not grant real host capabilities
  - Each container process maps to unprivileged host UIDs
EOF
```
