# Environment Variables and Shell Configuration

The shell environment controls how commands find programs, where tools look for config files, and what defaults are applied. Understanding it is essential for scripting and customization.

## env — View the Environment

```bash
env                     # print all environment variables
env | grep PATH         # find a specific variable
env | sort              # sorted list
printenv PATH           # print a single variable
printenv                # same as env
```

## Variables

```bash
# Local variable (current shell only, not inherited by child processes)
MY_VAR="hello"
echo $MY_VAR

# Environment variable (inherited by child processes)
export MY_VAR="hello"
export PORT=8080

# Both at once
export DB_HOST="localhost" DB_PORT="5432"

# Unset a variable
unset MY_VAR

# Read-only
readonly MAX_RETRIES=3
```

## PATH — Command Search Order

```bash
echo $PATH                   # colon-separated list of directories
which python3                # which PATH entry provides python3

# Add to PATH (prepend to override system versions)
export PATH="/usr/local/go/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Permanently: put the export line in ~/.bashrc
```

When you type `ls`, the shell searches each directory in `$PATH` in order and runs the first match.

## Special Variables

```bash
$?      # exit code of last command (0 = success, non-zero = error)
$!      # PID of last background process
$$      # PID of current shell
$0      # name of the current script/shell
$HOME   # home directory
$USER   # current username
$SHELL  # current shell binary
$PWD    # current directory (same as pwd)
$OLDPWD # previous directory (what cd - uses)
$TERM   # terminal type
$EDITOR # default text editor
```

```bash
ls /tmp
echo $?    # prints 0

ls /nonexistent
echo $?    # prints non-zero (e.g., 2)

sleep 10 &
echo $!    # PID of the sleep process
```

## Variable Expansion

```bash
${VAR}              # basic (useful when adjacent to text)
${VAR:-default}     # use default if VAR is unset or empty
${VAR:=default}     # assign default if unset
${VAR:?error msg}   # exit with error if unset
${VAR:+alt}         # use alt if VAR is set
${#VAR}             # length of VAR
${VAR#prefix}       # remove shortest prefix match
${VAR##prefix}      # remove longest prefix match
${VAR%suffix}       # remove shortest suffix match
${VAR%%suffix}      # remove longest suffix match
${VAR/old/new}      # replace first match
${VAR//old/new}     # replace all matches
```

## Shell Startup Files

| File | When loaded |
|------|-------------|
| `~/.bashrc` | Every interactive non-login bash shell |
| `~/.bash_profile` | Login shells (ssh, tty login) |
| `~/.profile` | Login shells (POSIX; also used by other shells) |
| `~/.bash_logout` | When login shell exits |
| `/etc/environment` | System-wide, all processes |
| `/etc/bash.bashrc` | System-wide bashrc |

**Rule of thumb**: Put environment variables and `export` in `~/.bash_profile`. Put aliases, functions, and prompt config in `~/.bashrc`. Have `~/.bash_profile` source `~/.bashrc`.

## source — Reload Config

```bash
source ~/.bashrc         # reload bashrc in current shell
. ~/.bashrc              # shorthand (. is an alias for source)
source script.sh         # run script in current shell (inherits variables)
```

Running a script normally (`bash script.sh`) spawns a subshell; changes to variables don't propagate back. `source` runs it in the current shell.

## alias — Command Shortcuts

```bash
alias ll='ls -lah'
alias grep='grep --color=auto'
alias ..='cd ..'
alias update='sudo apt update && sudo apt upgrade -y'

alias              # list all defined aliases
unalias ll         # remove an alias
```

Add aliases to `~/.bashrc` to make them permanent.

## Further Reading

- [man7.org — environ(7)](https://man7.org/linux/man-pages/man7/environ.7.html) — Defines the `environ` array, how it is passed to child processes on `exec`, and the `PATH` search convention.
- [GNU Bash Manual — Shell Variables](https://www.gnu.org/software/bash/manual/bash.html#Shell-Variables) — Complete list of every special bash variable (`HISTSIZE`, `IFS`, `PROMPT_COMMAND`, etc.) and how each is used.
- [GNU Bash Manual — Bash Startup Files](https://www.gnu.org/software/bash/manual/bash.html#Bash-Startup-Files) — Definitive description of which file is loaded for login shells, interactive shells, and non-interactive scripts.
- [Arch Wiki — Environment variables](https://wiki.archlinux.org/title/Environment_variables) — Practical guide to setting variables per-user, per-session, and system-wide using `/etc/environment`, `profile.d`, and PAM.
- [man7.org — execve(2)](https://man7.org/linux/man-pages/man2/execve.2.html) — The syscall that passes the environment block to a new process; explains why variables must be `export`ed to appear in child processes.
