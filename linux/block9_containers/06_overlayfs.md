# OverlayFS and Container Layers

## What Is OverlayFS?

**OverlayFS** is a union filesystem built into the Linux kernel that merges two directory trees into a single unified view. It is the default storage driver for Docker and other container runtimes because it efficiently implements copy-on-write (CoW) layering.

## The Four Directories

| Directory | Role |
|-----------|------|
| `lowerdir` | Read-only; can be multiple layers separated by `:` |
| `upperdir` | Read-write; container writes go here |
| `workdir`  | Internal scratch space required by the kernel (must be on same filesystem as upper) |
| `merged`   | The unified view processes see; mount point for the overlay |

## Mounting an OverlayFS

```bash
# Create the four directories
mkdir -p /tmp/overlay/{lower,upper,work,merged}
echo "from-image" > /tmp/overlay/lower/readme.txt

# Mount the overlay
sudo mount -t overlay overlay \
  -o lowerdir=/tmp/overlay/lower,upperdir=/tmp/overlay/upper,workdir=/tmp/overlay/work \
  /tmp/overlay/merged

# Read the file — comes from lower
cat /tmp/overlay/merged/readme.txt   # "from-image"

# Write a file — goes to upper
echo "container write" > /tmp/overlay/merged/newfile.txt
ls /tmp/overlay/upper/   # newfile.txt appears here
ls /tmp/overlay/lower/   # only readme.txt — unchanged
```

## Copy-on-Write Semantics

Reading a file that exists only in `lowerdir` reads directly from lower — no copy occurs. Writing to that file triggers a copy to `upperdir` first, then the write modifies the upper copy. The lower file is never changed.

```bash
# Modify the lower file through merged (triggers CoW)
echo "modified" > /tmp/overlay/merged/readme.txt
# A copy now exists in upper:
cat /tmp/overlay/upper/readme.txt   # "modified"
cat /tmp/overlay/lower/readme.txt   # "from-image" — still unchanged
```

Deleting a file creates a **whiteout** file in upper (a character device with device number 0) that masks the file in lower.

## How Docker Uses OverlayFS

Docker stores its overlay layers under `/var/lib/docker/overlay2/`:

```bash
sudo ls /var/lib/docker/overlay2/
# Each subdirectory is a layer ID with: diff/ link lower merged work
```

Each image layer is a `lowerdir`. When you run a container, Docker creates a new `upperdir` for that container's writes. Multiple image layers are stacked using `:` in `lowerdir`:

```bash
# Example (simplified) Docker overlay mount:
# -o lowerdir=layer3/diff:layer2/diff:layer1/diff,upperdir=container/diff,workdir=container/work
```

## Inspecting Docker Layers

```bash
# See the layers for an image
docker inspect ubuntu:22.04 | jq '.[0].GraphDriver'

# See the mount for a running container
docker inspect <container> | jq '.[0].GraphDriver.Data'

# On the host, find the merged mount
mount | grep overlay
```

## Multiple Lower Dirs (Stacked Layers)

OverlayFS supports stacking multiple read-only lower directories:

```bash
sudo mount -t overlay overlay \
  -o lowerdir=/layer3:/layer2:/layer1,upperdir=/upper,workdir=/work \
  /merged
```

The leftmost directory in `lowerdir` has the highest precedence — it overrides layers to its right.

## Cleanup

```bash
sudo umount /tmp/overlay/merged
sudo rm -rf /tmp/overlay
```

## Key Takeaways

- OverlayFS merges `lowerdir` (read-only) + `upperdir` (writable) into `merged`.
- Reads come from whichever layer has the file; writes go to `upperdir` via CoW.
- `workdir` is required by the kernel and must be on the same filesystem as `upper`.
- Docker stacks multiple image layers as `lowerdir`, one `upperdir` per container.
- Deleting files creates whiteout entries in `upperdir`.
- Inspect Docker's overlay setup at `/var/lib/docker/overlay2/` and via `docker inspect`.

## Further Reading

- [kernel.org: OverlayFS documentation](https://www.kernel.org/doc/html/latest/filesystems/overlayfs.html) — The authoritative kernel documentation for OverlayFS covering whiteout file semantics, opaque directory handling, `workdir` requirements, and multiple `lowerdir` stacking syntax.
- [Docker overlay2 storage driver](https://docs.docker.com/storage/storagedriver/overlayfs-driver/) — Docker's documentation for the overlay2 storage driver, covering the `/var/lib/docker/overlay2/` layer layout, the `diff`/`link`/`lower`/`work` directory structure, and performance characteristics.
- [Julia Evans: How containers work — overlayfs](https://jvns.ca/blog/2019/11/18/how-containers-work--overlayfs/) — A hands-on explanation of OverlayFS copy-on-write semantics with exact commands replicating the `mount -t overlay` sequence in this lesson and examining the resulting directory state.
