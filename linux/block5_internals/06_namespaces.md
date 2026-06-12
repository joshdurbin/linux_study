# Linux Namespaces

## What Are Namespaces?

Linux **namespaces** are a kernel feature that isolates global system resources so that processes within a namespace see their own isolated instance of that resource. They are the foundational technology behind containers — Docker, Podman, and LXC all rely on namespaces to create isolated environments.

Each process belongs to exactly one namespace of each type. Namespaces are inherited by child processes and can be shared or separated using `unshare` and `nsenter`.

## The 8 Namespace Types

| Namespace | Flag | Isolates |
|-----------|------|---------|
| **PID** | `CLONE_NEWPID` | Process IDs — a new PID 1 in the namespace |
| **NET** | `CLONE_NEWNET` | Network interfaces, routing tables, iptables |
| **MNT** | `CLONE_NEWNS` | Mount points — filesystem view |
| **UTS** | `CLONE_NEWUTS` | Hostname and NIS domain name |
| **IPC** | `CLONE_NEWIPC` | SysV IPC, POSIX message queues |
| **USER** | `CLONE_NEWUSER` | UIDs and GIDs — can be root inside but not outside |
| **TIME** | `CLONE_NEWTIME` | System clock offsets (Linux 5.6+) |
| **CGROUP** | `CLONE_NEWCGROUP` | cgroup root directory view |

## Viewing Namespace Memberships

```bash
# List all namespaces on the system
lsns

# List namespaces for a specific PID
lsns -p $$

# Every process has namespace symlinks in /proc
ls -la /proc/$$/ns/
# lrwxrwxrwx 1 student student 0 Jun  1 10:00 ipc -> ipc:[4026531839]
# lrwxrwxrwx 1 student student 0 Jun  1 10:00 mnt -> mnt:[4026531840]
# lrwxrwxrwx 1 student student 0 Jun  1 10:00 net -> net:[4026531992]
# lrwxrwxrwx 1 student student 0 Jun  1 10:00 pid -> pid:[4026531836]
# lrwxrwxrwx 1 student student 0 Jun  1 10:00 uts -> uts:[4026531838]
# lrwxrwxrwx 1 student student 0 Jun  1 10:00 user -> user:[4026531837]
```

The numbers in brackets are the namespace **inode numbers** — processes sharing a namespace have the same inode.

## unshare: Creating New Namespaces

`unshare` creates a new namespace and runs a command inside it.

### UTS Namespace (Hostname Isolation)

```bash
# Change hostname in an isolated namespace — host is unaffected
sudo unshare --uts bash -c 'hostname container-host; echo "Inside: $(hostname)"'
echo "Outside: $(hostname)"   # Original hostname preserved
```

### PID Namespace

```bash
# Create new PID namespace — inside, the first process is PID 1
sudo unshare --fork --pid --mount-proc bash
echo "My PID: $$"    # Should be 1 or a small number
ps aux               # Only sees processes in this namespace
exit
```

### Network Namespace

```bash
# Create isolated network namespace — no interfaces except lo
sudo unshare --net bash -c 'ip addr show'
# Only loopback appears, and it's DOWN
```

### Mount Namespace

```bash
# Create isolated mount namespace — changes don't affect host
sudo unshare --mount bash -c '
    mount -t tmpfs tmpfs /mnt
    echo "Mounted tmpfs at /mnt (host is unaffected)"
    mount | grep /mnt
'
# After exiting, /mnt on host is unchanged
```

## nsenter: Joining Existing Namespaces

`nsenter` enters the namespaces of a running process. Used to "get inside" a container without using `docker exec`.

```bash
# Enter all namespaces of PID 1234
sudo nsenter -t 1234 --all bash

# Enter only the network namespace of a container
sudo nsenter -t 1234 --net ip addr show

# Enter the mount namespace to inspect filesystem
sudo nsenter -t 1234 --mount ls /

# Common pattern: enter a Docker container by PID
CONTAINER_PID=$(docker inspect --format '{{.State.Pid}}' my-container)
sudo nsenter -t $CONTAINER_PID --net --pid bash
```

## How Namespaces Enable Containers

A container is essentially a process (or process tree) placed into a set of new namespaces at creation time:

1. **PID namespace**: Container processes have their own PID space; a daemon appears as PID 1 inside
2. **NET namespace**: Container gets its own network interfaces, routing, iptables
3. **MNT namespace**: Container sees a different filesystem root (its image)
4. **UTS namespace**: Container has its own hostname
5. **USER namespace**: Container processes can be "root" inside without host privileges
6. **IPC namespace**: Container's IPC objects don't interfere with host

```bash
# See what namespaces a Docker container uses vs the host
docker run --rm busybox cat /proc/1/ns/pid
cat /proc/1/ns/pid
# Different inodes = different namespaces
```

## Persistent Namespaces

A namespace lives as long as at least one process is in it, OR a bind mount holds it open:

```bash
# Create a persistent network namespace
sudo ip netns add myns

# This creates /var/run/netns/myns as a bind mount
ls /var/run/netns/

# Run commands in it
sudo ip netns exec myns ip addr show

# Delete it
sudo ip netns delete myns
```

## Further Reading

- [namespaces(7) — man7.org](https://man7.org/linux/man-pages/man7/namespaces.7.html) — the definitive overview of all eight namespace types, their `CLONE_NEW*` flags, `/proc/PID/ns/` symlink semantics, lifetime rules, and the `ioctl_ns(2)` API for querying namespace relationships.
- [LWN — Namespaces in operation series](https://lwn.net/Articles/531114/) — Michael Kerrisk's seven-part LWN series introducing each namespace type with annotated C programs demonstrating isolation from first principles.
- [Julia Evans — What even is a container?](https://jvns.ca/blog/2016/10/10/what-even-is-a-container/) — accessible explanation of how namespaces and cgroups combine to create containers, with shell command demonstrations of each namespace type.
- [clone(2) — man7.org](https://man7.org/linux/man-pages/man2/clone.2.html) — documents the `clone(2)` syscall that Docker and container runtimes use internally; covers every `CLONE_NEW*` flag and `CLONE_THREAD` for threads vs processes.
- [unshare(1) — man7.org](https://man7.org/linux/man-pages/man1/unshare.1.html) — complete reference for the `unshare` command including `--fork`, `--mount-proc`, `--map-root-user`, and the `--propagation` flag for controlling mount propagation in new namespaces.
