# Shell Interpreters

When you run a script, something has to execute it. That something is an **interpreter** — and which one runs determines what syntax is valid, what features are available, and how your script behaves.

## The Shebang Line

The first line of a script, if it starts with `#!`, tells the kernel which interpreter to use:

```bash
#!/bin/bash          # use bash explicitly
#!/bin/sh            # use the system's POSIX sh
#!/usr/bin/env bash  # find bash via PATH (more portable)
#!/usr/bin/env python3
#!/usr/bin/env node
```

The kernel reads the first two bytes (`#!`), treats the rest as the interpreter path, and exec's it with the script as its argument. Without a shebang, the behavior is shell-dependent — bash typically runs the script as bash, but you cannot rely on this.

### Why `#!/usr/bin/env bash`?

`/bin/bash` hardcodes the path. On some systems (NixOS, macOS with Homebrew), bash may be at `/usr/local/bin/bash` or `/opt/homebrew/bin/bash`. Using `env` finds whatever `bash` appears first in `$PATH`:

```bash
which bash          # tells you where bash actually is
env bash --version  # run bash via env, same as #!/usr/bin/env bash would
```

The tradeoff: `env` searches PATH, so if PATH is manipulated, a different `bash` could run. For system scripts and cron jobs, `/bin/bash` is safer. For user scripts, `#!/usr/bin/env bash` is more portable.

## Common Interpreters

| Shebang | Shell/Interpreter | Notes |
|---------|------------------|-------|
| `#!/bin/bash` | Bash | Most features, most common |
| `#!/bin/sh` | POSIX sh | Minimal; on Ubuntu, sh is `dash` |
| `#!/usr/bin/env python3` | Python 3 | |
| `#!/usr/bin/env node` | Node.js | |
| `#!/usr/bin/awk -f` | awk | For standalone awk programs |

## bash vs sh vs dash

On Ubuntu and Debian, `/bin/sh` is **dash** — a minimal POSIX-compliant shell that is significantly faster to start than bash but lacks many bash-specific features.

```bash
ls -la /bin/sh        # symlink on Ubuntu: sh -> dash
readlink /bin/sh      # dash

# Features in bash but NOT in sh/dash:
# - Arrays: arr=(1 2 3)
# - [[ ]] double brackets
# - $RANDOM, $BASHPID
# - Process substitution: <(cmd)
# - Brace expansion in certain forms
# - HISTCONTROL, HISTSIZE, shopt

# This works in bash but fails in sh:
[[ "hello" == "hello" ]]   # OK in bash
[ "hello" = "hello" ]      # POSIX: works in both
```

If you write `#!/bin/sh` and use bash-specific syntax, your script will fail when run on systems where `sh` is not bash — including Ubuntu's cron jobs and Docker containers.

### Running a Script Explicitly

```bash
bash script.sh       # run with bash regardless of shebang
sh script.sh         # run with sh (dash on Ubuntu)
dash script.sh       # run with dash explicitly

# Check for bashisms in a sh script (requires checkbashisms from devscripts)
# checkbashisms script.sh
```

## /etc/shells — Valid Login Shells

`/etc/shells` lists paths the system considers valid login shells:

```bash
cat /etc/shells
# /bin/sh
# /bin/bash
# /usr/bin/bash
# /bin/rbash
# /usr/bin/rbash
# /bin/dash
# /usr/bin/dash
```

`chsh` (change shell) will only accept paths listed in `/etc/shells`.

## chsh — Change Your Login Shell

Your login shell (used when you SSH in or open a terminal) is stored in `/etc/passwd`:

```bash
# View your current login shell
echo $SHELL
grep "^$USER:" /etc/passwd | cut -d: -f7

# Change login shell (must be in /etc/shells)
chsh -s /bin/bash    # switch to bash
chsh -s /bin/dash    # switch to dash
chsh                 # interactive prompt
```

The change takes effect on next login, not in the current session. `$SHELL` reflects the login shell, not necessarily the shell currently running.

## Shell Types and Their Startup Files

Not all shells load the same configuration files:

| Shell Type | What it Is | Startup Files |
|------------|-----------|---------------|
| Login shell | First shell after login (ssh, tty) | `~/.bash_profile`, then `~/.bashrc` if sourced |
| Interactive non-login | New terminal window/tab | `~/.bashrc` |
| Non-interactive | Script run via `bash script.sh` | None (inherits environment) |

```bash
# Detect shell type
[[ $- == *i* ]] && echo "interactive" || echo "non-interactive"
shopt -q login_shell && echo "login shell" || echo "non-login shell"
```

## Checking the Running Interpreter

```bash
echo $SHELL       # your login shell
echo $0           # name of the current shell or script
                  # "bash" if interactive bash
                  # "./script.sh" if running a script

# Inside a script, $0 is the script name
bash -c 'echo $0'    # bash
sh   -c 'echo $0'    # sh
dash -c 'echo $0'    # dash

# Get the full path of the running interpreter
readlink /proc/$$/exe    # e.g., /usr/bin/bash or /usr/bin/dash
```

## Script Execution: Shebang vs Explicit Interpreter

```bash
./script.sh          # kernel uses the shebang line
bash script.sh       # shebang is ignored; bash runs it
source script.sh     # runs in the current shell; shebang is ignored
. script.sh          # same as source
```

When you call `bash script.sh`, the shebang is just a comment — bash never sees it. This matters when testing sh-compatibility: `bash script.sh` doesn't tell you if `sh script.sh` works.

## Further Reading

- [man7.org — execve(2)](https://man7.org/linux/man-pages/man2/execve.2.html) — Documents the kernel's shebang (`#!`) parsing: how the interpreter path and optional single argument are extracted from the first 128 bytes before exec.
- [GNU Bash Manual — Bash Startup Files](https://www.gnu.org/software/bash/manual/bash.html#Bash-Startup-Files) — Definitive reference for which rc/profile files are loaded by login, interactive, and non-interactive shells.
- [Arch Wiki — Bash](https://wiki.archlinux.org/title/Bash) — Covers bash vs dash, startup file load order, POSIX mode, and common bashism pitfalls when writing portable scripts.
- [Greg's Bash Guide — The Shebang](https://mywiki.wooledge.org/BashGuide/Practices#Choosing_Your_Shell) — Explains the trade-offs between `#!/bin/bash`, `#!/bin/sh`, and `#!/usr/bin/env bash` for portability and security.
- [BashFAQ/096 — How do I determine whether a script is running in bash or sh?](https://mywiki.wooledge.org/BashFAQ/096) — Covers detecting the running interpreter at runtime, useful for writing scripts that degrade gracefully under dash.
