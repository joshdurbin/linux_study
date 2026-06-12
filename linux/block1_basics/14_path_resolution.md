# PATH and Command Resolution

When you type a command, the shell doesn't magically know where to find it. It follows a precise resolution process. Understanding it lets you control which version of a tool runs, diagnose "command not found" errors, and safely override system tools.

## How the Shell Finds a Command

When you type `python3`, the shell:

1. Checks if it's a **shell builtin** (e.g., `cd`, `echo`, `type`) — runs it directly
2. Checks if it's an **alias** — runs the alias expansion
3. Checks if it's a **shell function** — runs the function
4. Searches each directory in `$PATH` **left to right** — runs the first match found

If no match is found: `bash: python3: command not found`

## type — What Is This Command?

`type` reveals exactly what a command name resolves to. Use this before `which`.

```bash
type ls          # ls is /usr/bin/ls
type cd          # cd is a shell builtin
type ll          # ll is aliased to `ls -lah'
type grep        # grep is /usr/bin/grep

# Show all matches in PATH order (not just the first)
type -a python3  # python3 is /usr/bin/python3
                 # python3 is /usr/local/bin/python3

# Just the type, for scripting
type -t ls       # "file"
type -t cd       # "builtin"
type -t ll       # "alias"
type -t myfunction  # "function"
```

## which — Find a Binary in PATH

`which` searches `$PATH` and prints the full path of the first match. Unlike `type`, it ignores builtins, aliases, and functions.

```bash
which python3    # /usr/bin/python3
which -a python3 # all matches in PATH order
which ls         # /usr/bin/ls
which cd         # (no output — cd is a builtin, which doesn't find it)
```

Use `type` when you want to know what the shell will actually run. Use `which` when you specifically need the filesystem path of a binary.

## command — Run the Builtin or PATH Binary (Skip Aliases)

```bash
command ls       # run /usr/bin/ls, bypassing any 'ls' alias
command -v ls    # print path if found, exit 0 — preferred for scripts
command -v docker > /dev/null 2>&1 && echo "docker installed" || echo "not found"
```

`command -v` is the POSIX-portable way to check if a binary exists in a script. It respects PATH but ignores aliases and functions.

## hash — The PATH Cache

The shell caches command locations in a **hash table** to avoid repeated PATH searches on every invocation.

```bash
hash             # show cached command paths and hit counts
hash python3     # force a PATH lookup and cache the result
hash -d python3  # delete python3 from the cache (force re-lookup next time)
hash -r          # clear the entire cache

# After installing a new binary in PATH, the cache may still point to the old location:
which python3    # /usr/local/bin/python3  (newly installed)
hash             # may still show /usr/bin/python3
hash -r          # clear cache — shell will re-search next invocation
```

Symptom: you installed a new version of a tool and the old version still runs. Run `hash -r` or open a new shell.

## PATH — Anatomy and Modification

```bash
echo $PATH
# /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Colon-separated. Shell searches left to right. First match wins.
```

### Prepend vs Append

```bash
# Prepend: your version takes priority over system version
export PATH="$HOME/.local/bin:$PATH"

# Append: system version takes priority (rarely what you want)
export PATH="$PATH:$HOME/.local/bin"
```

Prepending is almost always correct when adding personal or project-specific tools.

### Persisting PATH Changes

Changes to `PATH` in the terminal are session-local. To persist:

```bash
# In ~/.bashrc (interactive shells)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Reload immediately
source ~/.bashrc

# System-wide (affects all users, all processes)
# /etc/environment  — KEY=VALUE format, no shell syntax
# /etc/profile.d/myapp.sh — for shell-specific config
```

### Common PATH Directories

| Directory | Contents |
|-----------|----------|
| `/usr/bin` | Most user commands |
| `/usr/sbin` | System admin commands (route, ifconfig, etc.) |
| `/bin` | Essential commands (ls, cp, bash) |
| `/sbin` | Essential system commands (fsck, ip) |
| `/usr/local/bin` | Locally installed software |
| `~/.local/bin` | User-installed scripts and tools |

`/sbin` and `/usr/sbin` are in PATH for root; regular users may or may not have them in their PATH depending on the distro.

## Diagnosing "command not found"

```bash
# 1. Is the binary installed at all?
find /usr -name python3 2>/dev/null
find / -name python3 -type f 2>/dev/null

# 2. Is its directory in PATH?
echo $PATH | tr ':' '\n'

# 3. Does the binary have execute permission? (permissions from block1/05)
ls -la /usr/bin/python3

# 4. Is the binary for the right architecture?
file /usr/bin/python3     # file is available in the container

# 5. Is the hash cache stale?
hash -r && python3 --version
```

## Absolute vs Relative Paths

```bash
/usr/bin/python3    # absolute path — bypasses PATH entirely
./myscript.sh       # relative to current directory — also bypasses PATH
python3             # searched via PATH

# Scripts in the current directory are NOT in PATH by default
myscript.sh         # fails: command not found
./myscript.sh       # works: explicit relative path
```

Never add `.` (current directory) to PATH — it's a security risk. An attacker who can write files to any directory you visit could plant a malicious `ls` or `python` there.

## Further Reading

- [man7.org — execvp(3)](https://man7.org/linux/man-pages/man3/execvp.3.html) — Documents the C library function that implements PATH search; shows exactly how directories are iterated and why the first match wins.
- [GNU Bash Manual — Command Search and Execution](https://www.gnu.org/software/bash/manual/bash.html#Command-Search-and-Execution) — Authoritative description of the exact resolution order: functions, builtins, aliases, then PATH.
- [man7.org — environ(7)](https://man7.org/linux/man-pages/man7/environ.7.html) — Explains how `PATH` is stored in the process environment and inherited across `fork`/`exec`.
- [Arch Wiki — Environment variables](https://wiki.archlinux.org/title/Environment_variables) — Covers persistent PATH modification for users, system-wide, and per-session including `profile.d` drop-ins.
- [BashFAQ — Why doesn't my script find the program I just installed?](https://mywiki.wooledge.org/BashFAQ/109) — Explains hash table caching and the `hash -r` fix for stale PATH lookups after installing new binaries.
