# Exercise: OCI Spec and runc

Complete the following tasks. Save your notes to `~/practice/oci_notes.txt`.

## Task 1 — Document OCI Bundle Structure

```bash
mkdir -p ~/practice
cat > ~/practice/oci_notes.txt << 'EOF'
OCI and runc Notes
===================
OCI = Open Container Initiative (Linux Foundation)
  - Image Spec: how container images are structured (layers, manifest, config)
  - Runtime Spec: what a runtime must implement (bundle format, lifecycle)

runc:
  - Reference implementation of OCI Runtime Spec
  - Low-level CLI: no daemon, no image management, no networking
  - Used by: Docker (via containerd), Podman, Kubernetes (via containerd/CRI-O)

OCI Bundle structure:
  bundle/
  ├── config.json   ← runtime configuration (process, mounts, namespaces, cgroups)
  └── rootfs/       ← root filesystem for the container

config.json key sections:
  process     - command, environment, working dir, user
  root        - path to rootfs, readonly flag
  mounts      - /proc, /dev, /sys, etc.
  linux       - namespaces, cgroupsPath, resources, capabilities, seccomp

Generate a default config.json:
  runc spec
EOF
```

## Task 2 — Document the runc Lifecycle Commands

```bash
cat >> ~/practice/oci_notes.txt << 'EOF'

runc Container Lifecycle
--------------------------
States: created → running → stopped → (deleted)

Commands:
  runc spec                        # generate default config.json
  runc create <id>                 # set up namespaces/cgroups, don't start process
  runc start <id>                  # start the process inside created container
  runc run <id>                    # create + start in one step
  runc list                        # show all containers managed by runc
  runc state <id>                  # show state of a container
  runc exec <id> <cmd>             # run a command inside running container
  runc kill <id> SIGTERM           # send signal to container
  runc delete <id>                 # delete stopped container

Key difference from Docker run:
  runc create sets up all kernel resources (namespaces, cgroups, mounts)
  but the process is paused until runc start is called.
  This allows the container manager (containerd) to do setup between create and start.
EOF
```

## Task 3 — Check if runc is Available

```bash
echo "" >> ~/practice/oci_notes.txt
echo "runc availability:" >> ~/practice/oci_notes.txt
if command -v runc &>/dev/null; then
  runc --version >> ~/practice/oci_notes.txt
else
  echo "runc not found in PATH" >> ~/practice/oci_notes.txt
  echo "Typical install path: /usr/sbin/runc or /usr/local/sbin/runc" >> ~/practice/oci_notes.txt
fi
```

## Task 4 — Document the Runtime Stack

```bash
cat >> ~/practice/oci_notes.txt << 'EOF'

Container Runtime Stack
------------------------
Docker CLI
    ↓ REST API
Docker daemon (dockerd)
    ↓ gRPC
containerd (image management, snapshots, container supervision)
    ↓ fork/exec
containerd-shim (keeps container running if containerd restarts)
    ↓ exec
runc (create OCI container: namespaces, cgroups, pivot_root, exec process)

Kubernetes uses containerd or CRI-O directly (bypasses Docker daemon):
  kubelet → CRI (containerd) → containerd-shim → runc
EOF
```

## Task 5 — Note config.json Namespace Types

```bash
cat >> ~/practice/oci_notes.txt << 'EOF'

config.json namespace types:
  pid       - process isolation
  network   - network stack isolation
  ipc       - inter-process communication isolation
  uts       - hostname/domain name isolation
  mount     - filesystem mount table isolation
  user      - UID/GID mapping (optional, for rootless)
  cgroup    - cgroup hierarchy isolation (optional)
EOF
```
