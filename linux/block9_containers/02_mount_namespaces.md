# Mount Namespaces

## What Is a Mount Namespace?

A mount namespace gives a process its own view of the filesystem mount table. Changes to mounts inside the namespace — mounting, unmounting, bind-mounts — are invisible to the host and to other namespaces. This is the foundation for giving containers an isolated root filesystem.

## Creating a Mount Namespace

```bash
# Enter a new mount namespace (host filesystem still visible at first)
sudo unshare --mount /bin/bash

# Verify: /proc/mounts now reflects this namespace only
cat /proc/mounts
```

Any `mount` or `umount` done inside this shell affects only the namespace.

## /proc/mounts vs /proc/PID/mounts

```bash
# Host-wide mount table
cat /proc/mounts

# Mount table for a specific process (e.g., a container's init)
cat /proc/<PID>/mounts

# Namespace identity
readlink /proc/self/ns/mnt
```

## chroot — Changing the Root

`chroot` changes the process's view of `/` to a specified directory. It is simple but incomplete for container isolation: the process still sees the host's mount table and PID namespace.

```bash
# Example: chroot into a minimal rootfs
sudo chroot /path/to/rootfs /bin/sh
```

## pivot_root — The Container Way

`pivot_root` is the kernel syscall containers actually use. It atomically swaps the root filesystem and moves the old root to a designated directory, then the old root is unmounted. This is more secure than `chroot` because there is no way to `chroot` back out.

```bash
# Inside a new mount namespace with a prepared rootfs at /new-root:
cd /new-root
mkdir -p old-root
pivot_root . old-root
cd /
umount -l /old-root
rmdir /old-root
```

## OverlayFS and Container Mounts

Containers combine a mount namespace with an overlay filesystem:

1. **Lower dir** — the read-only image layers
2. **Upper dir** — the writable container layer
3. **Work dir** — temporary space required by the kernel
4. **Merged** — the unified view processes see

```bash
# What Docker does for /proc, /sys, /dev inside a container:
# bind-mount from host into the container's mount namespace
mount --bind /proc /new-root/proc
mount --bind /sys  /new-root/sys
mount --bind /dev  /new-root/dev
```

## Inspecting Container Mount Namespaces

```bash
# Find the PID of a running container's init process
docker inspect --format '{{.State.Pid}}' <container>

# See that container's mounts
cat /proc/<container_pid>/mounts

# Compare inode with host
readlink /proc/1/ns/mnt           # host mount namespace
readlink /proc/<container_pid>/ns/mnt  # container mount namespace (different inode)
```

## Key Takeaways

- Mount namespaces let each container have an independent filesystem view.
- `unshare --mount` creates a namespace; initial contents mirror the host.
- `chroot` changes the root directory but does not create a new namespace.
- `pivot_root` is the correct way to switch root in a container runtime — it is used by runc.
- After `pivot_root`, `/proc`, `/sys`, and `/dev` must be re-mounted inside the new root.
- The mount namespace inode is at `/proc/PID/ns/mnt`.

## Further Reading

- [mount_namespaces(7) man page](https://man7.org/linux/man-pages/man7/mount_namespaces.7.html) — Documents mount propagation types (shared/slave/private/unbindable), the `/proc/PID/mounts` interface, and how `MS_PRIVATE` prevents bind-mounts from leaking between container and host namespaces.
- [pivot_root(2) man page](https://man7.org/linux/man-pages/man2/pivot_root.2.html) — Documents the `pivot_root` syscall semantics, the requirements for the new-root directory, and why it is more secure than `chroot` for container runtimes like runc.
- [LWN: Mount namespaces and shared subtrees](https://lwn.net/Articles/689856/) — LWN deep dive into mount propagation (shared, slave, private, unbindable subtrees) that explains why Docker bind-mounts from the host appear inside containers but container mounts don't affect the host.
- [chroot(2) man page](https://man7.org/linux/man-pages/man2/chroot.2.html) — Documents `chroot` semantics and its limitations (no new namespace, can be escaped by root), explaining why `pivot_root` is the correct container primitive.
