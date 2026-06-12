# nsenter — Entering Linux Namespaces

`nsenter` lets you run a command inside the namespaces of another process. This is exactly what `docker exec` does under the hood, and it's how you inspect running containers without using Docker at all.

## Namespace Types and /proc/PID/ns/

Every process has namespace memberships visible as symlinks:

```bash
ls -la /proc/$$/ns/
# lrwxrwxrwx cgroup -> cgroup:[4026531835]
# lrwxrwxrwx ipc    -> ipc:[4026531839]
# lrwxrwxrwx mnt    -> mnt:[4026531840]
# lrwxrwxrwx net    -> net:[4026531992]
# lrwxrwxrwx pid    -> pid:[4026531836]
# lrwxrwxrwx uts    -> uts:[4026531838]
# lrwxrwxrwx user   -> user:[4026531837]
# lrwxrwxrwx time   -> time:[4026531834]
```

Two processes sharing a namespace inode number share that namespace.

## nsenter Usage

```bash
# Enter all namespaces of PID 1234
sudo nsenter --target 1234 --all -- /bin/bash

# Enter only the network namespace
sudo nsenter --target 1234 --net -- ip addr show

# Enter mount + PID namespace (container-like)
sudo nsenter --target 1234 --mount --pid -- ls /

# Specific namespace flags
nsenter --target PID
  --cgroup     # cgroup namespace
  --ipc        # IPC namespace  
  --mount      # mount namespace (--mount=/proc/PID/ns/mnt also works)
  --net        # network namespace
  --pid        # PID namespace
  --uts        # UTS (hostname) namespace
  --user       # user namespace
  --time       # time namespace
  --all        # all namespaces

# Run as root inside the target's user namespace
sudo nsenter --target 1234 --user --preserve-credentials -- whoami
```

## Finding Container PIDs

```bash
# Find the PID of a Docker container's init process
docker inspect --format '{{.State.Pid}}' <container_name>

# Then enter its network namespace to debug
sudo nsenter --target $(docker inspect -f '{{.State.Pid}}' mycontainer) \
  --net -- ss -tlnp

# Or its filesystem
sudo nsenter --target $(docker inspect -f '{{.State.Pid}}' mycontainer) \
  --mount --pid -- ls /etc
```

## lsns — List All Namespaces

```bash
lsns                     # all namespaces on the system
lsns -t net              # only network namespaces
lsns -t pid
lsns -p 1234             # namespaces belonging to PID 1234

# Output: NS (inode), TYPE, NPROCS (processes in namespace), PID, USER, COMMAND
```

## unshare — Create New Namespaces

```bash
# New network namespace (isolated from host)
sudo unshare --net -- ip addr show
# Shows only loopback — completely isolated

# New UTS (hostname) namespace
unshare --uts -- bash -c "hostname test-ns && hostname"
# Changes hostname only inside the new namespace

# New PID namespace with its own /proc
sudo unshare --pid --fork --mount-proc -- bash
# PID 1 inside, your shell is PID 1

# Simulate a minimal container
sudo unshare --pid --fork --mount-proc --uts --ipc --net -- bash
```

## Practical Debugging Patterns

```bash
# Debug networking inside a running container without docker exec
PID=$(docker inspect -f '{{.State.Pid}}' nginx-container)
sudo nsenter --target $PID --net -- tcpdump -i eth0 -n

# Check what DNS resolver a container is using
sudo nsenter --target $PID --net --mount -- cat /etc/resolv.conf

# Compare namespace memberships of two processes
diff <(ls -la /proc/1/ns/) <(ls -la /proc/$$/ns/)
```

## Further Reading

- [setns(2) — man7.org](https://man7.org/linux/man-pages/man2/setns.2.html) — the kernel API that `nsenter` is built on: how to pass a namespace fd from `/proc/PID/ns/`, which capabilities are required for each namespace type, and the `CLONE_NEWUSER` restrictions.
- [nsenter(1) — man7.org](https://man7.org/linux/man-pages/man1/nsenter.1.html) — complete `nsenter` reference covering every namespace flag, `--preserve-credentials`, `--target`, and how the tool handles the `--pid` namespace bootstrapping with `/proc` remounting.
- [unshare(1) — man7.org](https://man7.org/linux/man-pages/man1/unshare.1.html) — documents `unshare` options including `--fork`, `--mount-proc`, `--map-root-user`, and `--propagation` — complementing `nsenter` for creating vs entering namespaces.
- [LWN — Namespaces in operation series](https://lwn.net/Articles/531114/) — Michael Kerrisk's seven-part series; parts 5–7 cover `nsenter`, `setns`, and user namespaces in detail with C code examples that match what `nsenter` does internally.
