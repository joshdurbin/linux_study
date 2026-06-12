# Exercise: Mount Namespaces

Complete the following tasks. Save your notes to `~/practice/mount_ns_notes.txt`.

## Task 1 — Document Core Concepts

Create notes explaining mount namespaces and the pivot_root approach:

```bash
mkdir -p ~/practice
cat > ~/practice/mount_ns_notes.txt << 'EOF'
Mount Namespace Notes
=====================
Mount namespaces isolate the filesystem mount table.
Changes to mounts inside the namespace are invisible to the host.

Creating a mount namespace:
  sudo unshare --mount /bin/bash

chroot:
  Changes the root directory for a process.
  Simple but incomplete: process still shares host mount table.
  Usage: sudo chroot /path/to/rootfs /bin/sh

pivot_root:
  Atomically swaps the root filesystem.
  More secure than chroot — used by real container runtimes (runc).
  Steps:
    1. Enter mount namespace (unshare --mount)
    2. cd into new rootfs
    3. mkdir old-root
    4. pivot_root . old-root
    5. umount -l /old-root

/proc/mounts        — current process mount table
/proc/<PID>/mounts  — mount table for a specific process
/proc/self/ns/mnt   — current mount namespace inode
EOF
```

## Task 2 — Record Your Current Mount Namespace Inode

```bash
echo "" >> ~/practice/mount_ns_notes.txt
echo "Current mount namespace inode:" >> ~/practice/mount_ns_notes.txt
readlink /proc/self/ns/mnt >> ~/practice/mount_ns_notes.txt
echo "Host init mount namespace inode:" >> ~/practice/mount_ns_notes.txt
readlink /proc/1/ns/mnt >> ~/practice/mount_ns_notes.txt
```

## Task 3 — Count Current Mounts

```bash
echo "" >> ~/practice/mount_ns_notes.txt
echo "Number of mounts in current namespace:" >> ~/practice/mount_ns_notes.txt
wc -l /proc/mounts >> ~/practice/mount_ns_notes.txt
```

## Task 4 — Document Container Mount Workflow

Append a step-by-step description of how Docker sets up mounts for a container:

```bash
cat >> ~/practice/mount_ns_notes.txt << 'EOF'

Docker Mount Setup Workflow
----------------------------
1. Create new mount namespace (CLONE_NEWNS flag)
2. Set up OverlayFS: lower=image layers, upper=container layer, work=scratch
3. pivot_root into the overlay merged directory
4. Bind-mount /proc, /sys, /dev from host into container root
5. Container processes see isolated filesystem with CoW writes going to upper layer
EOF
```

## Task 5 — Explore /proc/mounts

Record the first 10 lines of your current mount table:

```bash
echo "" >> ~/practice/mount_ns_notes.txt
echo "First 10 entries from /proc/mounts:" >> ~/practice/mount_ns_notes.txt
head -10 /proc/mounts >> ~/practice/mount_ns_notes.txt
```
