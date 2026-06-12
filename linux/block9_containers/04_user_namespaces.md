# User Namespaces

## What Is a User Namespace?

A user namespace maps UIDs and GIDs inside the namespace to different UIDs and GIDs on the host. The most common use is mapping a non-root user outside the namespace to UID 0 (root) inside — this is called **rootless containers**.

User namespaces are the only namespace type that can be created without root privileges (depending on kernel config), making them foundational to unprivileged container runtimes like rootless Podman and rootless Docker.

## Creating a User Namespace

```bash
# Map current user to root inside a new user namespace
unshare --user --map-root-user /bin/bash

# Inside the namespace:
id                  # uid=0(root) gid=0(root)
whoami              # root
```

On the host, the shell process still runs as your normal user. Inside the namespace it appears as root.

## UID and GID Maps

Mappings are defined in two files per process:

```bash
# Format: <namespace-id>  <host-id>  <count>
# Map UID 0 in namespace to UID 1000 on host, for 1 user:
cat /proc/self/uid_map    # e.g., "0  1000  1"
cat /proc/self/gid_map
```

You can write these files to set up custom mappings. Tools like `newuidmap` and `newgidmap` help configure sub-UID ranges defined in `/etc/subuid` and `/etc/subgid`.

```bash
# Check your sub-UID range
grep $(whoami) /etc/subuid    # e.g., student:100000:65536
grep $(whoami) /etc/subgid
```

## Rootless Containers

In rootless mode:
- Container runtime runs as a regular user
- Inside the container the process sees itself as UID 0
- On the host the process runs as the real user (or mapped sub-UIDs)
- No privileged kernel operations are needed to start containers

```bash
# Rootless Docker (Docker Desktop or configured daemon)
docker run --rm alpine id    # uid=0(root) inside container

# Check that the container process is NOT root on the host:
ps aux | grep <container_name>
```

## Security Implications

User namespaces expand attack surface. Several kernel CVEs have involved user namespace escapes:

- **CVE-2022-0492** — cgroup v1 release_agent escape via user + cgroup namespaces
- **CVE-2023-32233** — nf_tables use-after-free reachable via user namespaces
- Many distributions (Ubuntu 22.04+) restrict unprivileged user namespace creation via:

```bash
# Check restriction (Ubuntu)
cat /proc/sys/kernel/unprivileged_userns_clone   # 0 = restricted, 1 = allowed

# Or via AppArmor in Ubuntu 23.10+
cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns
```

## Combining Namespaces

User namespaces are often combined with PID, mount, and network namespaces for full container isolation without root:

```bash
unshare --user --map-root-user --mount --pid --fork --mount-proc /bin/bash
```

## Inspecting Namespace Ownership

```bash
# Which user namespace owns a given namespace?
ls -la /proc/self/ns/

# Show user namespace inode
readlink /proc/self/ns/user

# See the owning user namespace of a process
cat /proc/<PID>/status | grep -E 'Uid|Gid|NStgid|NSpid'
```

## Key Takeaways

- User namespaces map UIDs/GIDs — UID 0 inside need not be root outside.
- `unshare --user --map-root-user` creates a rootless "root" shell.
- UID/GID mappings are visible at `/proc/PID/uid_map` and `/proc/PID/gid_map`.
- Sub-UID ranges in `/etc/subuid` enable large UID space for rootless containers.
- User namespaces are powerful but have historically been a source of kernel CVEs.

## Further Reading

- [user_namespaces(7) man page](https://man7.org/linux/man-pages/man7/user_namespaces.7.html) — The authoritative reference for UID/GID mapping rules, the `uid_map`/`gid_map` file format, capability semantics inside user namespaces, and the `unprivileged_userns_clone` restriction on Ubuntu.
- [LWN: User namespaces](https://lwn.net/Articles/532593/) — LWN's introduction to user namespaces explaining why they were controversial, how the UID mapping works, and the security implications that led to the `unprivileged_userns_clone` sysctl.
- [rootlesscontaine.rs](https://rootlesscontaine.rs/) — The comprehensive guide to rootless containers covering Podman, Docker rootless mode, user namespace setup, `/etc/subuid`, and the security trade-offs compared to privileged containers.
