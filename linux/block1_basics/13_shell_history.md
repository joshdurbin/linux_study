# Shell History

The shell records every command you run. Knowing how to search, reuse, and control that history dramatically cuts down on retyping.

## The history Command

```bash
history           # print all recorded commands with line numbers
history 20        # last 20 commands
history | grep ssh  # search history output with grep (from block1/04)
```

Each line is numbered. That number is used for recall and editing.

## History Expansion — Reusing Commands

```bash
!!          # repeat the last command
sudo !!     # re-run last command with sudo (very common)

!n          # run command number n from history (e.g., !42)
!-2         # run the command 2 before this one
!ssh        # run the most recent command starting with "ssh"
!?conf      # run the most recent command containing "conf"

# Word designators — parts of a previous command
!$          # last argument of the previous command
!*          # all arguments of the previous command
!^          # first argument of the previous command

echo /etc/hosts
cat !$      # cat /etc/hosts  (reuses the last argument)

cp /etc/hosts /tmp/hosts.bak
ls -la !*   # ls -la /etc/hosts /tmp/hosts.bak
```

Use `echo !!` or `echo !ssh` to preview what will be expanded before running it.

## Ctrl-R — Reverse Incremental Search

Press **Ctrl-R** in an interactive shell to search backward through history:

```
(reverse-i-search)`ssh': ssh -i ~/.ssh/id_rsa user@server
```

- Type characters to narrow the match
- Press **Ctrl-R** again to jump to the next older match
- Press **Enter** to run the matched command
- Press **Ctrl-G** or **Escape** to cancel without running
- Press **→** or **Ctrl-E** to bring the match to the prompt for editing

## Other History Navigation

```bash
Ctrl-P   # previous command (same as Up arrow)
Ctrl-N   # next command (same as Down arrow)
Alt-.    # insert last argument of previous command (like !$)
         # press multiple times to cycle through previous last-args
```

## HIST* Environment Variables

These variables control how history works. Put them in `~/.bashrc` to make them permanent.

```bash
HISTSIZE=10000        # number of commands kept in memory for the current session
HISTFILESIZE=20000    # number of lines stored in the history file on disk
HISTFILE=~/.bash_history  # where history is saved (default)
HISTTIMEFORMAT="%F %T "   # prefix each entry with a timestamp (date + time)
HISTCONTROL=ignoredups    # don't record a command if it's the same as the previous
HISTCONTROL=ignorespace   # don't record commands that start with a space
HISTCONTROL=ignoreboth    # both of the above
HISTIGNORE="ls:ll:cd:pwd:exit:history"  # colon-separated patterns to exclude
```

The `HISTTIMEFORMAT` setting is powerful for auditing — once set, `history` shows when each command was run:

```
10007  2024-03-15 14:32:01 sudo apt update
10008  2024-03-15 14:32:45 df -h
```

### A Recommended ~/.bashrc Block

```bash
HISTSIZE=50000
HISTFILESIZE=100000
HISTTIMEFORMAT="%F %T "
HISTCONTROL=ignoreboth
HISTIGNORE="ls:ll:history:pwd:exit"
shopt -s histappend        # append to history file instead of overwriting
```

`shopt -s histappend` is important when running multiple terminal sessions — without it, the last session to close overwrites the history file with only its own commands.

## Managing History

```bash
history -c          # clear the in-memory history (doesn't touch the file)
history -w          # write current session history to HISTFILE immediately
history -r          # reload HISTFILE into memory
history -d 42       # delete a specific entry by line number
history -d 42 5     # delete 5 entries starting at line 42 (bash 5.1+)

# Prefix with a space to skip recording (requires HISTCONTROL=ignorespace)
 secret_command      # ← leading space, not saved to history
```

## Searching History Without Ctrl-R

```bash
# grep through the history file directly (grep from block1/04)
grep "docker" ~/.bash_history

# Use history + grep for the current session's in-memory commands
history | grep "kubectl"

# Most recent unique commands (sort/uniq from block2/02)
history | awk '{print $2}' | sort | uniq -c | sort -rn | head -20
```

## Further Reading

- [GNU Bash Manual — Using History Interactively](https://www.gnu.org/software/bash/manual/bash.html#Using-History-Interactively) — The authoritative reference for history expansion (`!!`, `!$`, `!*`), `HISTCONTROL`, `HISTIGNORE`, and the readline history library.
- [BashFAQ/088 — How do I use history in a script or non-interactive shell?](https://mywiki.wooledge.org/BashFAQ/088) — Covers `history -s`, `HISTFILE`, `shopt -s histappend`, and the subtleties of multi-session history merging.
- [Greg's Bash Guide — History](https://mywiki.wooledge.org/BashGuide/TheArtOfSourcing) — Part of the comprehensive bash guide covering how history, `source`, and startup files interact.
- [The Linux Command Line — Keyboard Tricks](https://linuxcommand.org/tlcl.php) — Chapter 8 covers Ctrl-R, `!!`, and `!$` with practical examples that show how history dramatically reduces retyping.
