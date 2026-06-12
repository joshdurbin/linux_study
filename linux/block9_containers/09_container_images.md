# Container Image Building

A container image is the immutable, portable package that a container runtime turns into a running container. Understanding how images are built — and what they actually are on disk — makes you a more effective operator: you can debug build failures, reduce image sizes, speed up CI pipelines, and reason about the security surface area of every container you run.

This lesson connects the overlay filesystem knowledge from block9/06 with the OCI spec from block9/07, and adds the practical build tooling on top.

## What Is a Container Image?

From block9/07: an OCI image is a set of **layers** plus a **manifest** and a **config**. Each layer is a tar archive of filesystem changes. The container runtime (Docker, containerd, runc) unpacks and stacks these layers into an overlay filesystem — exactly the `lowerdir` stacking you explored in block9/06.

```
Image on disk (registry / local cache):
  manifest.json      ← points to config + layer blobs
  config.json        ← entrypoint, env vars, working dir, labels, history
  layer1.tar.gz      ← base OS files (e.g., ubuntu 24.04 rootfs)
  layer2.tar.gz      ← apt packages added in RUN step
  layer3.tar.gz      ← application binary copied in COPY step

At runtime (overlayfs):
  lowerdir = layer1 : layer2 : layer3   (read-only, stacked)
  upperdir = container writable layer   (copy-on-write changes)
  merged   = what the process sees
```

Every `RUN`, `COPY`, and `ADD` instruction in a Dockerfile creates a new layer. `ENV`, `LABEL`, `EXPOSE`, `CMD`, `ENTRYPOINT` do not create layers — they are metadata stored in `config.json`.

## Dockerfile Syntax

```dockerfile
# Comment
FROM ubuntu:24.04                    # Base image — defines starting lowerdir

RUN apt-get update && \              # Execute command in a new layer
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

COPY ./myapp /usr/local/bin/myapp    # Copy files from build context into image

ADD https://example.com/file.tar.gz /tmp/   # ADD can fetch URLs and auto-extract tarballs

WORKDIR /app                         # Sets working directory (creates if needed)

ENV APP_PORT=8080                    # Environment variable — baked into config.json

EXPOSE 8080                          # Documents which ports the container listens on
                                     # Does NOT publish the port — purely metadata

ARG BUILD_VERSION=dev                # Build-time variable (not in final image)

LABEL version="1.0" \               # Image metadata
      maintainer="ops-team"

USER nobody                          # Switch to non-root user

ENTRYPOINT ["/usr/local/bin/myapp"]  # Main executable — cannot be overridden by CMD args
CMD ["--config", "/etc/app.conf"]    # Default args to ENTRYPOINT (overridable at run time)
```

### CMD vs ENTRYPOINT

| | ENTRYPOINT | CMD |
|---|---|---|
| Purpose | The executable to run | Default arguments |
| Override | Requires `--entrypoint` flag | Overridden by any args after image name |
| Typical use | Server binary | Config flags |

```dockerfile
# Common pattern:
ENTRYPOINT ["/usr/local/bin/server"]
CMD ["--port", "8080"]

# docker run myimage                      → server --port 8080
# docker run myimage --port 9090          → server --port 9090
# docker run --entrypoint /bin/bash myimage  → bash
```

Use **exec form** (`["cmd", "arg"]`) over **shell form** (`cmd arg`) for ENTRYPOINT and CMD. Shell form wraps the command in `/bin/sh -c`, which means PID 1 is `/bin/sh`, not your binary — signal handling (SIGTERM) breaks.

## Layer Caching

Docker caches each instruction result. On rebuild, if the instruction and its inputs haven't changed, Docker reuses the cached layer.

```
Cache HIT  → layer reused, sub-millisecond
Cache MISS → layer rebuilt (RUN executes, COPY re-copies, etc.)
```

**Cache invalidation rules**:
- `FROM`: cache depends on tag/digest of base image
- `RUN`: cache invalidated if the instruction text changes
- `COPY` / `ADD`: cache invalidated if any copied file's content changes
- Any invalidation propagates to **all subsequent layers**

**Implication**: put slow, rarely-changing instructions early; put frequently-changing instructions late.

```dockerfile
# SLOW BUILD — source code change invalidates apt-get layer
FROM ubuntu:24.04
COPY . /app          ← source changes here
RUN apt-get install -y python3   ← re-runs every time source changes

# FAST BUILD — reorder to cache apt layer
FROM ubuntu:24.04
RUN apt-get install -y python3   ← cached unless FROM changes
COPY . /app          ← only this and below re-run on source change
```

## Multi-Stage Builds

Multi-stage builds are the standard way to produce minimal production images. You use a fat builder image to compile, then copy only the output artifact into a minimal runtime image.

```dockerfile
# Stage 1: builder (has full build toolchain)
FROM golang:1.22 AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download                   # cached unless go.mod changes
COPY . .
RUN CGO_ENABLED=0 go build -o /app ./cmd/server

# Stage 2: runtime (minimal)
FROM ubuntu:24.04
RUN apt-get update && \
    apt-get install -y ca-certificates && \
    rm -rf /var/lib/apt/lists/*
COPY --from=builder /app /usr/local/bin/app
USER nobody
ENTRYPOINT ["/usr/local/bin/app"]
```

The final image contains only Ubuntu 24.04 + ca-certificates + the binary. The Go compiler, source code, build cache, and intermediate files are in the `builder` stage and do not appear in the final image.

### Scratch base

For fully static binaries, use `FROM scratch` — an empty image with no OS at all:

```dockerfile
FROM golang:1.22 AS builder
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /app .

FROM scratch
COPY --from=builder /app /app
ENTRYPOINT ["/app"]
```

The resulting image is just the binary. Typical size: 5–20 MB vs 200+ MB for a Ubuntu-based image.

## BuildKit

BuildKit is Docker's modern build engine (default since Docker 23). It provides:

- **Parallel execution**: independent stages build concurrently
- **Better caching**: content-addressable cache, cache mounts
- **Secrets**: `--secret` flag mounts credentials during build without baking them into layers
- **SSH forwarding**: `--ssh` for private git repo access during build

```bash
# BuildKit is enabled by default in modern Docker
docker build .

# Explicit BuildKit enable for older Docker:
DOCKER_BUILDKIT=1 docker build .

# Cache mount — share apt cache between builds (not stored in layer)
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y curl

# Secret mount — use a credential during build, not baked into image
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc \
    npm install
# Build with: docker build --secret id=npmrc,src=$HOME/.npmrc .
```

## .dockerignore

`.dockerignore` excludes files from the **build context** — the directory tree sent to the Docker daemon at build time. Without it, every file in the build directory is sent, including:
- `.git/` (often hundreds of MB)
- `node_modules/` (hundreds of MB of deps)
- Test fixtures, logs, local config

```
# .dockerignore
.git
.gitignore
*.md
node_modules
dist
*.log
.env
.env.*
__pycache__
*.pyc
tests/
```

The build context is transferred before any Dockerfile instruction runs. A large context means slower builds even if the COPY instruction copies only a few files.

## Inspecting Images

### docker image ls — list images

```bash
docker image ls
docker image ls --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.ID}}"
```

### docker history — layer breakdown

```bash
docker history ubuntu:24.04
docker history --no-trunc myapp:latest
```

Output shows each layer's size, creation time, and the command that created it. Useful for spotting bloated layers.

```
IMAGE          CREATED       CREATED BY                                SIZE
4ef0bd0ea16d   2 weeks ago   /bin/sh -c #(nop)  CMD ["/bin/bash"]      0B
<missing>      2 weeks ago   /bin/sh -c #(nop) ADD file:...             78.1MB
```

Layers with size 0 are metadata instructions (CMD, ENV, LABEL, EXPOSE). Large layers came from RUN or COPY.

### docker inspect — full image metadata as JSON

```bash
docker inspect ubuntu:24.04
docker inspect --format '{{.Config.Entrypoint}}' myapp:latest
docker inspect --format '{{json .Config.Labels}}' myapp:latest | jq .
```

`docker inspect` returns a JSON array. Key fields:

```json
{
  "Id": "sha256:...",
  "RepoTags": ["myapp:latest"],
  "Config": {
    "Hostname": "",
    "Env": ["PATH=/usr/local/sbin:..."],
    "Cmd": ["--port", "8080"],
    "Entrypoint": ["/usr/local/bin/app"],
    "WorkingDir": "/app",
    "Labels": {}
  },
  "RootFS": {
    "Type": "layers",
    "Layers": ["sha256:abc...", "sha256:def...", "sha256:ghi..."]
  }
}
```

`RootFS.Layers` lists the layer digests — each is the sha256 of the uncompressed tar of that layer's filesystem diff.

### docker image inspect vs docker inspect

```bash
docker image inspect myapp:latest      # image-specific metadata
docker inspect myapp:latest            # same, but works for any object type
docker container inspect mycontainer  # running container metadata
```

## Image Layers on Disk (Connecting to block9/06)

Docker's overlay2 storage driver stores layers at `/var/lib/docker/overlay2/`. Each directory is a layer:

```bash
ls /var/lib/docker/overlay2/
# Each directory: <layer-id>/
#   diff/    ← the actual filesystem files for this layer
#   link     ← short ID used in overlayfs lowerdir string
#   lower    ← parent layer links
#   work/    ← overlayfs workdir (for writable layers)
```

When a container runs, Docker mounts these using `overlayfs`:
```
lowerdir=layer3-link:layer2-link:layer1-link
upperdir=<container-id>/diff
workdir=<container-id>/work
merged=<container-id>/merged
```

This is exactly the mount structure from block9/06. The image is just multiple read-only lower dirs stacked from bottom (base image) to top (most recent layer).

View a running container's overlay mount:
```bash
docker inspect <container-id> | jq '.[0].GraphDriver.Data'
# Shows:  LowerDir, UpperDir, WorkDir, MergedDir
```

```bash
# Verify by looking at /proc/mounts
mount | grep overlay
```

## Base Image Selection

| Base | Size | Use case |
|---|---|---|
| `scratch` | 0 bytes | Fully static binaries (Go, Rust) |
| `alpine:3` | ~7 MB | Small images where musl libc is acceptable |
| `debian:slim` | ~30 MB | Good compromise: glibc, minimal packages |
| `ubuntu:24.04` | ~78 MB | Familiar tooling, LTS support |
| `ubuntu:24.04-minimal` | ~36 MB | Ubuntu without snaps/extra packages |
| `distroless/*` | ~5-20 MB | Google's no-shell production bases |

Alpine uses `musl` libc, not `glibc`. Some Go/C applications compiled against glibc crash on Alpine. Test before committing to Alpine.

## Minimizing Image Size

**1. Chain RUN commands and clean up in the same layer**
```dockerfile
# Bad: cleanup is a separate layer, doesn't reduce size
RUN apt-get install -y curl
RUN rm -rf /var/lib/apt/lists/*

# Good: one layer, cleanup included
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*
```

**2. Use multi-stage builds** (see above) — keep build toolchain out of production image.

**3. Use .dockerignore** to avoid copying unnecessary files.

**4. Don't copy secrets or credentials** — even if deleted in a later layer, they exist in an earlier layer and can be extracted.

**5. Pin versions** for reproducibility:
```dockerfile
FROM ubuntu:24.04                      # bad: "latest" implicit
FROM ubuntu:24.04@sha256:abc123...     # good: pinned by digest
RUN apt-get install -y curl=8.5.*      # version pinned
```

## Image Signing (Concepts)

Container image signing ensures you can verify that an image came from a trusted source and hasn't been tampered with.

**Notation** (CNCF): Signs OCI artifacts using X.509 certificates. Signatures stored as OCI artifacts alongside the image in the registry.

**Cosign** (Sigstore): Key-less signing using OIDC identities. The signature is stored in the registry alongside the image.

```bash
# Sign an image (cosign)
cosign sign --key cosign.key myregistry.com/myapp:latest

# Verify
cosign verify --key cosign.pub myregistry.com/myapp:latest
```

In Kubernetes, admission controllers (Kyverno, OPA/Gatekeeper) can enforce that only signed images are deployed.

## docker build Reference

```bash
# Basic build (context = current directory)
docker build -t myapp:latest .

# Specific Dockerfile
docker build -f Dockerfile.prod -t myapp:prod .

# Build arg
docker build --build-arg BUILD_VERSION=1.2.3 -t myapp:1.2.3 .

# No cache (force full rebuild)
docker build --no-cache -t myapp:latest .

# Multi-platform (BuildKit)
docker buildx build --platform linux/amd64,linux/arm64 -t myapp:latest --push .

# Build target (stop at a specific stage)
docker build --target builder -t myapp:builder .
```

## Further Reading

- [OCI Image Format Specification](https://github.com/opencontainers/image-spec) — The spec defining the image manifest, config JSON, and layer tar format — the standard that makes images built with `docker build` portable to any OCI-compliant runtime.
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/) — Complete documentation for every Dockerfile instruction (`FROM`, `RUN`, `COPY`, `ADD`, `ENTRYPOINT`, `CMD`, `ARG`, `LABEL`) and their caching semantics.
- [BuildKit documentation](https://docs.docker.com/build/buildkit/) — Covers BuildKit's parallel stage execution, `RUN --mount=type=cache`, `RUN --mount=type=secret`, and `--ssh` for private git access — all the advanced build features described in this lesson.
- [Julia Evans: How containers work — overlayfs](https://jvns.ca/blog/2019/11/18/how-containers-work--overlayfs/) — Connects image layers (OCI tarballs) to the OverlayFS `lowerdir` stacking at runtime, making the `RootFS.Layers` field in `docker inspect` output concrete.
