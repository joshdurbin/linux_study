# apt Sources, Policy, and Package Management Depth

apt is Debian/Ubuntu's high-level package manager. Understanding its internals — sources, policy, holds, and dependency resolution — makes you far more effective when something goes wrong.

## Sources List Format

`/etc/apt/sources.list` and files in `/etc/apt/sources.list.d/` define where apt fetches packages.

```
# One-line format (classic)
deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable

# Fields: type  [options]  uri  suite  components
#  type:   deb (binaries) or deb-src (source)
#  suite:  release codename (bookworm, jammy) or class (stable, testing)
#  components: main restricted universe multiverse
```

List active sources:
```bash
apt-cache policy               # shows all configured repos and priorities
cat /etc/apt/sources.list
ls /etc/apt/sources.list.d/
```

## apt-cache: Query Without Installing

```bash
apt-cache show nginx           # full metadata: version, deps, description
apt-cache policy nginx         # installed vs candidate version, repo priorities
apt-cache depends nginx        # what nginx requires
apt-cache rdepends nginx       # what depends ON nginx (reverse deps)
apt-cache search "web server"  # full-text search
apt-cache madison nginx        # all available versions across all repos
```

## Dependency Types

| Field | Meaning |
|-------|---------|
| `Depends` | Must be installed before this package |
| `Pre-Depends` | Must be configured before this package installs |
| `Recommends` | Installed by default unless `--no-install-recommends` |
| `Suggests` | Optional, not installed by default |
| `Conflicts` | Cannot be installed alongside this package |
| `Breaks` | This package breaks when the other is present |
| `Replaces` | This package replaces files from another |
| `Provides` | Virtual package name this satisfies |

## Holding Packages

Prevents a package from being upgraded (critical for pinned infrastructure):

```bash
apt-mark hold nginx            # prevent upgrades
apt-mark unhold nginx          # re-enable upgrades
apt-mark showhold              # list held packages
dpkg --get-selections | grep hold   # alternative view
```

## Cache Management

```bash
apt clean                      # remove all downloaded .deb files
apt autoclean                  # remove only obsolete .deb files
apt autoremove                 # remove automatically-installed deps no longer needed
du -sh /var/cache/apt/archives # see cache size
```

## Useful apt Flags

```bash
apt install -y --no-install-recommends nginx   # skip Recommends
apt install nginx=1.24.0-1ubuntu1              # install specific version
apt list --installed                           # list installed packages
apt list --upgradable                          # what can be upgraded
```

## Further Reading

- [Debian APT User's Guide](https://www.debian.org/doc/manuals/apt-guide/) — Official guide to APT sources, `apt-get`, `apt-cache`, and dependency resolution; includes the DEB822 multi-line sources format.
- [man7.org — apt_preferences(5)](https://man7.org/linux/man-pages/man5/apt_preferences.5.html) — The authoritative specification for pin priorities, `apt-cache policy` output interpretation, and the preferences file format.
- [Ubuntu Server Docs — Package Management](https://ubuntu.com/server/docs/package-management) — Ubuntu-specific guidance on sources, PPAs, `apt-mark hold`, and repository signing with `signed-by=`.
- [Debian Policy Manual — The Debian archive](https://www.debian.org/doc/debian-policy/ch-archive.html) — Defines the `Release` file fields (`Origin`, `Label`, `Suite`, `Codename`) that pin rules match against.
- [man7.org — sources.list(5)](https://man7.org/linux/man-pages/man5/sources.list.5.html) — Full sources.list format reference including the modern DEB822 format and the `[signed-by=]` option.
