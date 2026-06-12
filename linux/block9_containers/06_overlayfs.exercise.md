# Exercise: OverlayFS and Container Layers

Complete the following tasks. Save your notes to `~/practice/overlayfs_notes.txt`.

## Task 1 — Document OverlayFS Concepts

```bash
mkdir -p ~/practice
cat > ~/practice/overlayfs_notes.txt << 'EOF'
OverlayFS Notes
================
OverlayFS is a union filesystem merging multiple directory trees into one view.
Used by Docker (and other runtimes) as the default storage driver.

Four required directories:
  lowerdir  - read-only layer(s); can stack multiple with ":" separator
  upperdir  - read-write layer; container writes land here
  workdir   - kernel scratch space; must be on same filesystem as upperdir
  merged    - the unified view that processes see

Mount command:
  sudo mount -t overlay overlay \
    -o lowerdir=/lower,upperdir=/upper,workdir=/work \
    /merged

Copy-on-write (CoW):
  - Reading from lower: no copy needed, read directly
  - Writing to a lower file: kernel copies file to upper first, then modifies upper
  - Deleting a lower file: creates a "whiteout" entry in upper

Multiple lower layers (stacked):
  lowerdir=/layer3:/layer2:/layer1  (leftmost = highest priority)

Docker overlay2 layout:
  /var/lib/docker/overlay2/<layer-id>/diff/   - layer contents
  /var/lib/docker/overlay2/<layer-id>/lower   - link to parent layers
  Container = image layers as lowerdir + one upperdir for writes
EOF
```

## Task 2 — Create a Working OverlayFS Demo

```bash
# Set up directories
mkdir -p /tmp/ov_demo/{lower,upper,work,merged}
echo "original content from image layer" > /tmp/ov_demo/lower/readme.txt

# Mount overlay (requires root)
if sudo mount -t overlay overlay \
  -o lowerdir=/tmp/ov_demo/lower,upperdir=/tmp/ov_demo/upper,workdir=/tmp/ov_demo/work \
  /tmp/ov_demo/merged 2>/dev/null; then

  echo "" >> ~/practice/overlayfs_notes.txt
  echo "OverlayFS demo results:" >> ~/practice/overlayfs_notes.txt
  echo "Lower dir contents: $(ls /tmp/ov_demo/lower/)" >> ~/practice/overlayfs_notes.txt
  echo "Merged view before write: $(cat /tmp/ov_demo/merged/readme.txt)" >> ~/practice/overlayfs_notes.txt

  # Write to merged — triggers CoW
  echo "container modification" > /tmp/ov_demo/merged/readme.txt
  echo "After write to merged:" >> ~/practice/overlayfs_notes.txt
  echo "  upper/readme.txt: $(cat /tmp/ov_demo/upper/readme.txt 2>/dev/null || echo 'not there')" >> ~/practice/overlayfs_notes.txt
  echo "  lower/readme.txt: $(cat /tmp/ov_demo/lower/readme.txt)" >> ~/practice/overlayfs_notes.txt

  sudo umount /tmp/ov_demo/merged
  rm -rf /tmp/ov_demo
else
  echo "" >> ~/practice/overlayfs_notes.txt
  echo "Note: overlay mount requires root (not available in this environment)" >> ~/practice/overlayfs_notes.txt
fi
```

## Task 3 — Document Whiteout Files

```bash
cat >> ~/practice/overlayfs_notes.txt << 'EOF'

Whiteout files:
  When a file from lowerdir is deleted inside the merged view,
  overlayfs creates a "whiteout" in upperdir.
  A whiteout is a character device with major:minor = 0:0.
  It signals to overlayfs: "this file is deleted, hide it from merged."
  
  Check for whiteouts: ls -la /var/lib/docker/overlay2/<layer>/diff/
EOF
```

## Task 4 — Check mount for overlay Entries

```bash
echo "" >> ~/practice/overlayfs_notes.txt
echo "Current overlay mounts on this system:" >> ~/practice/overlayfs_notes.txt
mount 2>/dev/null | grep overlay >> ~/practice/overlayfs_notes.txt || echo "(no overlay mounts found)" >> ~/practice/overlayfs_notes.txt
```
