# dpkg Internals

dpkg is the low-level Debian package manager. apt sits on top of it. When apt fails, you work with dpkg directly.

## The dpkg Database

```
/var/lib/dpkg/
├── status          # installed packages and their state
├── available       # package metadata from last apt-get update
├── info/           # per-package: conffiles, list, md5sums, postinst, prerm...
└── updates/        # pending state updates
```

`/var/lib/dpkg/info/nginx.list` contains every file installed by nginx.

## Status Codes in `dpkg -l`

```bash
dpkg -l              # list all packages
dpkg -l "nginx*"     # filter by name glob
```

The first two letters are state codes:
```
ii  = installed, ok
rc  = removed but config files remain
iU  = installed, unpacked but not configured
hi  = installed, hold
```

## Key dpkg Queries

```bash
dpkg -L nginx                  # list all files installed by a package
dpkg -S /usr/bin/curl          # which package owns this file
dpkg -c package.deb            # list contents of a .deb before installing
dpkg -I package.deb            # show metadata from a .deb file
dpkg --get-selections          # all packages with their selection state
dpkg --get-selections | grep hold   # held packages
```

## Fixing Broken Installs

```bash
dpkg --audit                   # find packages in inconsistent states
sudo dpkg --configure -a       # configure all unconfigured packages
sudo dpkg-reconfigure tzdata   # re-run post-install configuration
sudo apt install -f            # fix broken dependencies ("fix broken")
```

## .deb Package Structure

A `.deb` is an `ar` archive containing:
```
debian-binary       # version string ("2.0")
control.tar.*       # control, md5sums, pre/postinst scripts, conffiles
data.tar.*          # actual filesystem contents
```

Extract manually:
```bash
ar x package.deb
tar tf data.tar.gz | head
```

## Conffiles

Config files managed by dpkg are listed in `debian/conffiles`. When you upgrade, dpkg prompts if a conffile has local modifications:
```
Configuration file '/etc/nginx/nginx.conf'
 ==> Modified (by you or by a script) since installation.
 ==> Package distributor has shipped an updated version.
   What would you like to do about it?  Your options are:
    Y or I  : install the package maintainer's version
    N or O  : keep your currently-installed version
```

Force non-interactive with `DEBIAN_FRONTEND=noninteractive` + `--force-confold` or `--force-confnew`.

## dpkg-divert

Diverts a file so dpkg doesn't overwrite it on upgrade:
```bash
sudo dpkg-divert --add --rename --divert /usr/bin/python.orig /usr/bin/python
sudo ln -s /usr/bin/python3 /usr/bin/python

## Further Reading

- [Debian Policy Manual — Binary packages](https://www.debian.org/doc/debian-policy/ch-binary.html) — The official specification for `.deb` structure, conffiles, maintainer scripts (`preinst`, `postinst`, `prerm`, `postrm`), and the control file format.
- [man7.org — dpkg(1)](https://man7.org/linux/man-pages/man1/dpkg.1.html) — Complete reference for dpkg flags, status codes (`ii`, `rc`, `hi`), and the `/var/lib/dpkg/` database layout.
- [man7.org — deb(5)](https://man7.org/linux/man-pages/man5/deb.5.html) — Documents the `.deb` archive format: the `ar` wrapper, `debian-binary`, `control.tar`, and `data.tar` components.
- [Debian Policy Manual — Configuration files](https://www.debian.org/doc/debian-policy/ch-files.html#configuration-files) — Defines conffile semantics — when dpkg prompts on upgrade, `--force-confold`/`--force-confnew`, and the three-way merge algorithm.
- [man7.org — dpkg-divert(1)](https://man7.org/linux/man-pages/man1/dpkg-divert.1.html) — Documents the `dpkg-divert` mechanism for permanently redirecting a file so package upgrades cannot overwrite it.
