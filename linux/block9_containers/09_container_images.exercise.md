# Container Image Building Exercises

These exercises build hands-on experience with Dockerfiles, image inspection, multi-stage builds, and connecting image layers to the overlay filesystem knowledge from block9/06.

## Setup

```bash
mkdir -p ~/practice/container_images
cd ~/practice/container_images

# Verify Docker is available
docker version
```

---

## Task 1: Write a Simple Dockerfile

Create a basic Dockerfile that installs `curl` on Ubuntu 24.04 and adds a custom entrypoint script.

```bash
mkdir -p ~/practice/container_images/simple
cd ~/practice/container_images/simple
```

Create `Dockerfile`:
```dockerfile
FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV APP_ENV=production

LABEL description="simple curl image" \
      maintainer="study-lab"

RUN echo '#!/bin/bash\necho "Hello from container! curl version:"\ncurl --version | head -1' \
    > /app/hello.sh && chmod +x /app/hello.sh

CMD ["/app/hello.sh"]
```

Build and run it:
```bash
docker build -t study-simple:v1 .
docker run --rm study-simple:v1
```

---

## Task 2: Observe Layer Creation

Look at what layers were created during the build.

```bash
docker history study-simple:v1
docker history --no-trunc study-simple:v1
```

Identify:
- Which instruction created the largest layer?
- Which instructions created 0-byte metadata layers?
- How many total layers does the image have?

Also list the image:
```bash
docker image ls study-simple:v1
```

---

## Task 3: Use docker history to Inspect Layer Sizes

Pull the official `ubuntu:24.04` base image and compare its history to your image:

```bash
docker pull ubuntu:24.04
docker history ubuntu:24.04
```

Now compare:
```bash
echo "=== ubuntu:24.04 layers ==="
docker history ubuntu:24.04 --format "table {{.Size}}\t{{.CreatedBy}}" | head -10

echo ""
echo "=== study-simple:v1 layers ==="
docker history study-simple:v1 --format "table {{.Size}}\t{{.CreatedBy}}"
```

Notice that your image's layers appear on top of the Ubuntu base layers.

---

## Task 4: Use docker inspect to Read Image Metadata

Inspect your image's full metadata:

```bash
docker inspect study-simple:v1
```

Now use `--format` to extract specific fields:

```bash
# Get the image ID
docker inspect --format '{{.Id}}' study-simple:v1

# Get the entrypoint and cmd
docker inspect --format 'Entrypoint: {{.Config.Entrypoint}}' study-simple:v1
docker inspect --format 'Cmd: {{.Config.Cmd}}' study-simple:v1

# Get the environment variables
docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' study-simple:v1

# Get the labels
docker inspect --format '{{json .Config.Labels}}' study-simple:v1

# Get all layer digests (RootFS)
docker inspect --format '{{range .RootFS.Layers}}{{println .}}{{end}}' study-simple:v1
```

Count the layers via inspect and verify it matches `docker history`:
```bash
docker inspect --format '{{len .RootFS.Layers}}' study-simple:v1
```

---

## Task 5: Write a Multi-Stage Dockerfile

Create a multi-stage build that compiles a small shell script into a minimal image. We'll use a "builder" stage to prepare the artifact and a slim runtime stage.

```bash
mkdir -p ~/practice/container_images/multistage
cd ~/practice/container_images/multistage
```

Create a simple application script `app.sh`:
```bash
cat > app.sh <<'EOF'
#!/bin/bash
echo "=== System Info ==="
echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
echo "Kernel: $(uname -r)"
echo ""
echo "=== Container Environment ==="
env | grep -E '^(APP_|HOSTNAME|PATH)' | sort
EOF
chmod +x app.sh
```

Create `Dockerfile.multistage`:
```dockerfile
# Stage 1: builder — validate and prepare the script
FROM ubuntu:24.04 AS builder

WORKDIR /build
COPY app.sh .

# Validate: ensure the script has a shebang and is executable
RUN bash -n /build/app.sh && \
    chmod 755 /build/app.sh && \
    echo "Script validated OK"

# Stage 2: runtime — minimal image with just what's needed
FROM ubuntu:24.04-minimal AS runtime

WORKDIR /app

# Copy only the validated artifact from builder
COPY --from=builder /build/app.sh /app/run.sh

ENV APP_NAME=study-app \
    APP_VERSION=1.0.0

LABEL stage=runtime \
      app=study-multistage

USER root

ENTRYPOINT ["/app/run.sh"]
```

Build both stages and compare sizes:
```bash
# Build the full final image
docker build -f Dockerfile.multistage -t study-multistage:v1 .

# Build just the builder stage to compare
docker build -f Dockerfile.multistage --target builder -t study-builder:v1 .

# Compare sizes
docker image ls study-multistage:v1 study-builder:v1

# Run the final image
docker run --rm study-multistage:v1
```

Observe that the final image does not contain any artifacts from the builder stage.

---

## Task 6: Use .dockerignore to Exclude Files

Create a build context with several files you want to exclude.

```bash
mkdir -p ~/practice/container_images/dockerignore
cd ~/practice/container_images/dockerignore

# Create files we want to include
echo "source code" > main.sh
echo "config value" > config.txt

# Create files we want to EXCLUDE
echo "secret-token-12345" > .env
echo "password=hunter2" > credentials.conf
mkdir -p .git && echo "git objects" > .git/HEAD
mkdir -p tests && echo "test data" > tests/test.sh
echo "debug output" > build.log
```

Without `.dockerignore`, all these files are in the build context. Create a `Dockerfile` that shows what's copied:

```dockerfile
FROM ubuntu:24.04
WORKDIR /app
COPY . .
RUN echo "=== Files in /app ===" && find /app -type f | sort
```

First build without `.dockerignore`:
```bash
docker build -t study-context:no-ignore . 2>&1 | tail -20
```

Now create `.dockerignore`:
```
.env
credentials.conf
*.conf
.git
tests/
*.log
```

Build again and observe the difference:
```bash
docker build -t study-context:with-ignore . 2>&1 | tail -20
```

Compare what ended up in each image:
```bash
echo "=== without .dockerignore ==="
docker run --rm study-context:no-ignore find /app -type f | sort

echo ""
echo "=== with .dockerignore ==="
docker run --rm study-context:with-ignore find /app -type f | sort
```

Confirm that `.env` and `credentials.conf` are absent from the second image.

---

## Task 7: Inspect OCI Image Layers on Disk

Connect the image layers back to the overlay filesystem from block9/06.

```bash
# Find where Docker stores image layers
ls /var/lib/docker/overlay2/ 2>/dev/null | head -20 || \
  echo "Note: /var/lib/docker may not be accessible in this container"

# If accessible, pick a layer ID from docker inspect and look at its diff/
LAYER_ID=$(docker inspect study-simple:v1 --format '{{index .GraphDriver.Data "UpperDir"}}' 2>/dev/null)
echo "UpperDir: $LAYER_ID"
```

Inspect the overlay mount of a running container to see the lowerdir stack:

```bash
# Run a container in background
CID=$(docker run -d --rm ubuntu:24.04 sleep 30)
echo "Container: $CID"

# Inspect its GraphDriver to see the overlay paths
docker inspect "$CID" | python3 -c "
import sys, json
data = json.load(sys.stdin)
gd = data[0].get('GraphDriver', {}).get('Data', {})
for k, v in gd.items():
    print(f'{k}:')
    # LowerDir can be very long — print each layer on a line
    if k == 'LowerDir':
        for layer in v.split(':'):
            print(f'  {layer}')
    else:
        print(f'  {v}')
"

# Count how many layers are stacked in lowerdir
docker inspect "$CID" --format '{{.GraphDriver.Data.LowerDir}}' | tr ':' '\n' | wc -l

# Clean up
docker stop "$CID" 2>/dev/null || true
```

Verify via `/proc/mounts` that a running container uses an overlay mount:
```bash
CID2=$(docker run -d --rm ubuntu:24.04 sleep 30)
mount | grep overlay | tail -5
grep overlay /proc/mounts | tail -3
docker stop "$CID2" 2>/dev/null || true
```

---

## Task 8: Write a Summary Notes File

Capture your observations in a notes file for future reference:

```bash
cat > ~/practice/container_images/image_notes.txt <<'EOF'
Container Image Building — Key Takeaways

1. Each RUN/COPY/ADD instruction creates a new image layer.
2. Layers are read-only; the running container adds a writable upperdir (overlayfs).
3. Layer caching: any changed instruction invalidates all subsequent layers.
4. Multi-stage builds: use a fat builder image, copy only output to slim runtime image.
5. .dockerignore: always exclude .git, .env, node_modules, test data from build context.
6. docker history shows layer sizes — use it to find bloated layers.
7. docker inspect gives full metadata: env vars, labels, entrypoint, layer digests.
8. Image layers on disk = /var/lib/docker/overlay2/<layer-id>/diff/ (overlayfs lowerdir).
EOF
```

---

## Reflection Questions

1. If a Dockerfile has 10 layers and you change layer 3, how many layers are rebuilt?
2. Why is it important to clean up (`rm -rf /var/lib/apt/lists/*`) in the same `RUN` instruction as `apt-get install`?
3. What is the difference between `CMD` in shell form and exec form, and why does it matter for signal handling?
4. How does a multi-stage build prevent secrets (e.g., private keys used during compilation) from ending up in the final image?
5. Connect back to block9/06: when you `docker run ubuntu:24.04`, how many directories are in the overlayfs `lowerdir`?
