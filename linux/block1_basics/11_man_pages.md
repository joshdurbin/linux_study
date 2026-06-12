# Man Pages and Documentation

The man page system is Linux's built-in reference. Knowing how to navigate it means you can self-serve on any installed tool without reaching for a search engine.

## Reading a Man Page

```bash
man ls          # the ls manual
man 5 passwd    # section 5: /etc/passwd file format (not the passwd command)
man man         # the manual for man itself
```

Navigate inside man (uses `less`):
```
Space / f    next page          b        previous page
/pattern     search forward     ?pattern  search backward
n            next match         N         previous match
g            top of page        G         bottom
q            quit
```

## Man Page Sections

Man pages are divided into numbered sections:

| Section | Contents |
|---------|----------|
| 1 | User commands (`ls`, `grep`, `ssh`) |
| 2 | System calls (`open`, `read`, `fork`, `mmap`) |
| 3 | C library functions (`printf`, `malloc`, `fopen`) |
| 4 | Device files (`/dev/null`, `/dev/random`) |
| 5 | File formats and conventions (`/etc/passwd`, `crontab`, `fstab`) |
| 6 | Games |
| 7 | Miscellaneous (`regex`, `tcp`, `signal`, `man`) |
| 8 | System administration commands (`fdisk`, `iptables`, `mount`) |

When the same name exists in multiple sections, specify the number:
```bash
man 1 printf    # the printf shell command
man 3 printf    # the C printf() function
man 5 crontab   # crontab file format
man 8 mount     # mount command (sysadmin)
```

## Finding Man Pages

```bash
man -k keyword         # search short descriptions (same as apropos)
man -k "list files"    # find pages related to listing files
apropos network        # all pages mentioning "network" in their description
whatis ls              # one-line description of ls

# Update the man page index (needed after installing new packages)
sudo mandb
```

`man -k` searches the whatis database — `mandb` builds it. If `apropos` returns nothing, run `sudo mandb` first.

## Practical man Navigation

```bash
# Quickly see the synopsis (usage line) without opening the full page
man ls | head -20

# Open a man page at a specific section
man --section=5 passwd

# All man pages for a name
man -a printf    # shows section 1, then asks if you want section 3

# Open in a specific pager
MANPAGER=cat man ls | head -30    # no pager, just text output

# man page for a shell builtin (bash docs are separate)
help cd          # bash builtin help
help if
```

## Other Documentation Sources

```bash
# --help: quick reference, faster than man
ls --help
grep --help | head -20

# info: GNU documentation system (more verbose than man)
info coreutils
info grep

# /usr/share/doc: package documentation, changelogs, examples
ls /usr/share/doc/openssl/
cat /usr/share/doc/bash/README

# README in common config locations
less /etc/ssh/sshd_config    # inline comments are often the best docs
```

## Reading Man Pages for System Calls and Files

```bash
# How does open() actually work?
man 2 open

# What fields does /etc/shadow have?
man 5 shadow

# All signals and their numbers
man 7 signal

# TCP socket options
man 7 tcp

# How are Linux capabilities defined?
man 7 capabilities
```

## Searching Within a Long Man Page

```bash
# Open man page and jump to a pattern immediately
man -P 'less +/pattern' ls

# Example: jump to the -l flag description
man -P 'less +/-l' ls
```

## Further Reading

- [man7.org — man(7)](https://man7.org/linux/man-pages/man7/man.7.html) — Describes the macro package and formatting conventions used to write man pages, explaining sections, `.SH` headings, and `.TP` option lists.
- [The Linux man-pages Project](https://www.kernel.org/doc/man-pages/) — The canonical kernel.org home of the Linux man-pages maintained by Michael Kerrisk, with release notes and contribution guidelines.
- [man-db documentation](https://nongnu.org/man-db/) — Reference for the `man` command itself: database building with `mandb`, `MANPATH`, and `MANPAGER` configuration.
- [The Linux Command Line — Getting Help](https://linuxcommand.org/tlcl.php) — Chapter 5 explains how to navigate man pages, use `apropos`, and get the most from `--help` and `info`.
- [Arch Wiki — man page](https://wiki.archlinux.org/title/Man_page) — Covers installing man pages, colourised output, alternative pagers, and the `mandoc` renderer as a replacement for groff.
