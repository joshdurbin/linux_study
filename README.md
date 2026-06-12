# linux_study

Linux training material for systems engineers, software engineers, and aspiring SREs. The course is meant to start shallow and become progressively deeper: shell basics, system services, storage, networking, kernel internals, performance analysis, eBPF, containers, and Linux-focused operations.

## Requirements

- Docker
- A working Go toolchain if you want to build from source
- A Linux host or Linux VM is recommended for the deepest labs. Docker Desktop can run the web app, but some kernel, networking, eBPF, cgroup, and systemd exercises behave differently outside a real Linux environment.

## Run The Training App

Pull the project, build the binary, and serve the web app:

```bash
git clone <repo-url>
cd linux_study
make build
./linux_study serve
```

Then open:

```text
http://localhost:8080/linux
```

You can also run:

```bash
make run
```

The app serves the lesson notes, exercise instructions, an in-browser terminal, and automated check scripts. The training terminal runs inside a Docker container built from `Dockerfile.linux`.

## Docker Image

Build the study container directly with:

```bash
make linux-image
```

Open an interactive shell in the image with:

```bash
make linux-shell
```

The app will try to use `linux-study:latest`. If the image is missing, it can fall back to a plain Ubuntu image, but many exercises expect the full study image.

## Course Content

Lessons live under `linux/`. Most topics have three files:

- `<topic>.md`: lesson notes
- `<topic>.exercise.md`: hands-on exercise
- `<topic>.check.sh`: automated validation script

The curriculum is Linux-first. Kubernetes, Prometheus, and SRE material should be treated as applied Linux operations context, not as replacements for the core Linux topics.

