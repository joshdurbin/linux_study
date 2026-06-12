# Package Management

On Ubuntu/Debian systems, `apt` is the primary tool for installing, updating, and removing software. Behind it is `dpkg`, the lower-level package manager that `apt` coordinates.

## apt — Advanced Package Tool

### Updating the Package Index

```bash
sudo apt update           # fetch latest package lists from repositories
sudo apt update -y        # non-interactive
```

Always run `apt update` before installing to get the latest versions.

### Upgrading Packages

```bash
sudo apt upgrade                  # upgrade installed packages
sudo apt upgrade -y               # auto-confirm all
sudo apt full-upgrade             # upgrade + remove obsolete packages
sudo apt dist-upgrade             # same as full-upgrade
sudo apt autoremove               # remove unneeded dependency packages
sudo apt autoclean                # clean old cached packages
```

### Installing and Removing

```bash
sudo apt install nginx             # install a package
sudo apt install nginx curl wget   # install multiple packages
sudo apt install -y nginx          # no confirmation prompt
sudo apt install ./local.deb       # install a local .deb file

sudo apt remove nginx              # remove package (keep config files)
sudo apt purge nginx               # remove package AND config files
sudo apt remove --purge nginx      # same as purge
```

### Searching and Inspecting

```bash
apt search nginx                   # search for packages
apt show nginx                     # detailed package info
apt list --installed               # all installed packages
apt list --installed | grep python # filter
apt list --upgradable              # packages with available upgrades
apt depends nginx                  # show dependencies
apt rdepends nginx                 # show what depends on nginx
```

### Package Cache

```bash
ls /var/cache/apt/archives/        # cached .deb files
sudo apt clean                     # remove all cached .deb files
sudo apt autoclean                 # remove cached .deb for old versions
```

## dpkg — Low-level Package Manager

```bash
dpkg -l                            # list all installed packages
dpkg -l | grep nginx               # check if nginx is installed
dpkg -l 'python*'                  # packages matching pattern
dpkg -s nginx                      # show package status/info
dpkg -L nginx                      # list files installed by nginx
dpkg -S /usr/bin/python3           # which package owns this file

sudo dpkg -i package.deb           # install a .deb file directly
sudo dpkg -r package               # remove a package
sudo dpkg --configure -a           # fix interrupted installations
```

## Locating Commands

```bash
which python3              # first match in PATH
which -a python3           # all matches in PATH
whereis python3            # binary, source, man page locations
type python3               # how the shell would interpret it
type -a python3            # all matches (aliases, functions, binaries)
```

These are essential for debugging "command not found" issues.

## APT Sources and PPAs

```bash
cat /etc/apt/sources.list           # main repository sources
ls /etc/apt/sources.list.d/         # additional repository sources

# Add a PPA (Personal Package Archive)
sudo add-apt-repository ppa:user/repo
sudo apt update
sudo apt install package
```

## Practical Workflow

```bash
# Check if a package is installed
dpkg -l | grep -q "^ii  nginx" && echo "installed" || echo "not installed"

# Install if not present
if ! command -v jq &>/dev/null; then
  sudo apt install -y jq
fi

# Find what provides a command
apt-file search /usr/bin/dig   # (requires apt-file package)

# Typical system maintenance
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
```

## Key Directories

| Path | Purpose |
|------|---------|
| `/etc/apt/sources.list` | APT repository list |
| `/var/cache/apt/archives/` | Downloaded .deb cache |
| `/var/lib/apt/lists/` | Package index files |
| `/var/lib/dpkg/info/` | Per-package metadata |

## Further Reading

- [Debian APT User's Guide](https://www.debian.org/doc/manuals/apt-guide/) — The official guide to APT covering sources, `apt-get`, `apt-cache`, preferences, and dependency resolution in depth.
- [Ubuntu Server Docs — Package Management](https://ubuntu.com/server/docs/package-management) — Ubuntu-specific guide covering `apt`, PPAs, `dpkg`, and handling held packages in production environments.
- [man7.org — dpkg(1)](https://man7.org/linux/man-pages/man1/dpkg.1.html) — Complete reference for all dpkg flags, status codes, and the `/var/lib/dpkg/` database layout.
- [man7.org — apt(8)](https://man7.org/linux/man-pages/man8/apt.8.html) — The full apt command reference including `list`, `depends`, `rdepends`, and cache management subcommands.
- [Debian Policy Manual — Relationships between packages](https://www.debian.org/doc/debian-policy/ch-relationships.html) — Defines every dependency type (`Depends`, `Recommends`, `Conflicts`, `Breaks`) that apt resolves when installing packages.
