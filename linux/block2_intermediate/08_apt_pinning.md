# apt Pinning

Pinning lets you fine-tune which version of a package apt installs or upgrades to — essential when mixing repos (e.g., enabling backports for a single package, or freezing a version across a fleet).

## Pin Priority Values

| Priority | Meaning |
|----------|---------|
| `< 0` | Never install this package |
| `1–99` | Install only if explicitly requested |
| `100` | Installed packages (default for already-installed) |
| `500` | Default repo (main archive) |
| `990` | Target release (`-t bookworm`) |
| `≥ 1000` | Installed even if it downgrades |
| `1001` | Force install even if it downgrades from a higher version |

## Preferences File Format

Create files in `/etc/apt/preferences.d/` (filename doesn't matter, but `.pref` is conventional):

```
# Pin nginx to a specific version
Package: nginx
Pin: version 1.24.*
Pin-Priority: 1001

# Prefer packages from backports only when explicitly requested
Package: *
Pin: release a=bookworm-backports
Pin-Priority: 100

# Never install a specific package
Package: snapd
Pin: release *
Pin-Priority: -1

# Pin a package to a specific origin (repo URL)
Package: docker-ce
Pin: origin download.docker.com
Pin-Priority: 990
```

## Pin Types

```
Pin: version 1.24.0-1        # exact version
Pin: version 1.24.*          # version prefix glob
Pin: release n=bookworm      # by suite codename
Pin: release a=stable        # by suite class (stable/testing/unstable)
Pin: release o=Ubuntu        # by origin (Origin field in Release file)
Pin: release l=Ubuntu        # by label
Pin: origin download.docker.com   # by URI hostname
```

## Checking Effective Policy

```bash
apt-cache policy nginx        # shows effective priority and version selection
apt-cache policy              # all repos with their priorities
```

## Practical Workflow: Install One Package from Backports

```bash
# 1. Add backports to sources (if not already present)
echo "deb http://deb.debian.org/debian bookworm-backports main" \
  | sudo tee /etc/apt/sources.list.d/backports.list

# 2. Pin backports low so it never auto-installs anything
cat > /etc/apt/preferences.d/backports.pref << 'EOF'
Package: *
Pin: release a=bookworm-backports
Pin-Priority: 100
EOF

# 3. Install a specific package from backports
sudo apt install -t bookworm-backports some-package
```

## Common Mistakes

- Pinning by version glob is brittle — `1.24.*` won't match `1.24.0-1ubuntu1` if you forgot the suffix pattern
- Priorities ≥ 1000 will **downgrade** installed packages — use carefully
- `apt-cache policy` is your best friend; always verify before applying

## Further Reading

- [man7.org — apt_preferences(5)](https://man7.org/linux/man-pages/man5/apt_preferences.5.html) — The authoritative specification for pin types (`version`, `release`, `origin`), priority values, and how apt selects the candidate version.
- [Debian Wiki — AptPreferences](https://wiki.debian.org/AptPreferences) — Practical Debian pinning HOWTO with worked examples for mixing stable and backports and blocking unwanted packages.
- [Ubuntu Wiki — UbuntuBackports](https://wiki.ubuntu.com/UbuntuBackports) — Documents the Ubuntu backports process, how to enable the backports pocket, and when to use `-t` target release pinning.
- [Debian APT User's Guide — Managing packages from multiple distributions](https://www.debian.org/doc/manuals/apt-guide/ch2.en.html) — Explains the priority system and how to safely pull individual packages from testing/unstable without upgrading the whole system.
