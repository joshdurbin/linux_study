# OCI Spec and runc

## The Open Container Initiative

The **Open Container Initiative (OCI)** is a Linux Foundation project that defines open standards for containers so that any runtime can run any compliant image. It produces two main specifications:

- **Image Spec**: How container images are structured (layers, manifest, config)
- **Runtime Spec**: What a container runtime must implement (the bundle format and lifecycle)

## runc

**runc** is the reference implementation of the OCI Runtime Spec. It is a low-level CLI tool — no daemon, no network, no image management. Higher-level tools (Docker via containerd, Podman, Kubernetes via containerd or CRI-O) all call runc (or a compatible runtime) to actually create and run containers.

```bash
# Check runc version
runc --version

# Where runc lives after Docker install
which runc    # typically /usr/sbin/runc or /usr/local/sbin/runc
```

## The OCI Bundle

An **OCI bundle** is a directory containing exactly two things:

```
bundle/
├── config.json    ← runtime configuration
└── rootfs/        ← the root filesystem
```

### config.json Key Sections

```json
{
  "ociVersion": "1.0.2",
  "process": {
    "terminal": true,
    "user": { "uid": 0, "gid": 0 },
    "args": ["/bin/sh"],
    "env": ["PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"],
    "cwd": "/"
  },
  "root": { "path": "rootfs", "readonly": false },
  "mounts": [
    { "destination": "/proc", "type": "proc", "source": "proc" },
    { "destination": "/dev",  "type": "devtmpfs", "source": "devtmpfs" }
  ],
  "linux": {
    "namespaces": [
      { "type": "pid" },
      { "type": "network" },
      { "type": "ipc" },
      { "type": "uts" },
      { "type": "mount" }
    ],
    "cgroupsPath": "/myapp",
    "resources": {
      "memory": { "limit": 104857600 }
    }
  }
}
```

## Creating a Bundle and Running a Container

```bash
# Generate a default config.json
runc spec    # creates config.json in current directory

# Create the rootfs (example using Docker to export)
docker export $(docker create busybox) | tar -C rootfs -xf -

# Container lifecycle:

# Create: set up namespaces, cgroups, mounts (does NOT start the process)
runc create mycontainer

# Start: execute the process inside the created container
runc start mycontainer

# List running containers
runc list

# Execute a command inside a running container
runc exec mycontainer /bin/sh

# Send signal / stop
runc kill mycontainer SIGTERM

# Clean up (delete stopped container)
runc delete mycontainer
```

## Container Lifecycle States

```
created → running → stopped → (deleted)
```

| State    | Description |
|----------|-------------|
| created  | Namespaces and cgroups set up; process not yet started |
| running  | Process is executing inside the container |
| stopped  | Process exited; container resources still exist |
| deleted  | Container metadata removed |

## runc vs containerd vs Docker

```
Docker CLI
    ↓
Docker daemon
    ↓
containerd (manages image pulls, snapshots, networking)
    ↓
containerd-shim
    ↓
runc (creates and runs the OCI container)
```

## Key Takeaways

- OCI standardizes image format and runtime interface so tools are interchangeable.
- An OCI bundle = `rootfs/` directory + `config.json` runtime config.
- `config.json` specifies process, mounts, namespaces, capabilities, and cgroups.
- `runc spec` generates a default `config.json` to start from.
- Container lifecycle: created → running → stopped; each managed by runc subcommands.
- runc is the low-level building block; Docker, Podman, and containerd all use it.

## Further Reading

- [OCI Runtime Specification](https://github.com/opencontainers/runtime-spec/blob/main/spec.md) — The full OCI Runtime Spec defining the bundle format, `config.json` schema, and the five lifecycle operations (create, start, kill, delete, state) that runc implements.
- [OCI Image Specification](https://github.com/opencontainers/image-spec) — The OCI Image Spec defining the image manifest, config, and layer tar format — the standard that enables images built with Docker to run on any OCI-compliant runtime.
- [runc documentation](https://github.com/opencontainers/runc) — The runc README and man pages covering `runc spec`, `runc create`, `runc start`, `runc exec`, and how runc integrates with containerd via the container shim.
- [containerd architecture](https://containerd.io/docs/) — Documents the containerd architecture showing where runc fits in the Docker → containerd → containerd-shim → runc stack, and how containerd manages image snapshots and container lifecycle.
