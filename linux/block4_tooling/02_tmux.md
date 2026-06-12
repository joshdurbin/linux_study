# tmux — Terminal Multiplexer

tmux lets you run multiple terminal sessions within a single connection, detach from them, and reattach later. It's essential for remote work and long-running processes.

## Core Concepts

```
Server  — tmux daemon (starts automatically, persists until all sessions end)
Session — a collection of windows (can detach and reattach)
Window  — like a tab; a single terminal view
Pane    — a split within a window
```

The default **prefix key** is `Ctrl-b`. Every tmux command starts by pressing `Ctrl-b`, releasing, then pressing the command key.

## Sessions

```bash
tmux                          # new session
tmux new -s mysession         # new named session
tmux ls                       # list sessions
tmux attach                   # attach to most recent session
tmux attach -t mysession      # attach by name
tmux kill-session -t name     # kill a session
tmux kill-server              # kill all sessions and the server
```

From inside tmux:
| Key | Action |
|-----|--------|
| `Ctrl-b d` | Detach from session |
| `Ctrl-b $` | Rename current session |
| `Ctrl-b (` | Previous session |
| `Ctrl-b )` | Next session |
| `Ctrl-b s` | Interactive session list |
| `Ctrl-b L` | Switch to last (previously used) session |

## Windows

| Key | Action |
|-----|--------|
| `Ctrl-b c` | Create new window |
| `Ctrl-b ,` | Rename current window |
| `Ctrl-b n` | Next window |
| `Ctrl-b p` | Previous window |
| `Ctrl-b w` | Interactive window list |
| `Ctrl-b 0-9` | Go to window by number |
| `Ctrl-b &` | Kill current window (confirm) |
| `Ctrl-b .` | Move window (renumber) |

## Panes (Splits)

| Key | Action |
|-----|--------|
| `Ctrl-b %` | Split horizontally (side by side) |
| `Ctrl-b "` | Split vertically (top/bottom) |
| `Ctrl-b arrow` | Move focus to pane in that direction |
| `Ctrl-b o` | Cycle through panes |
| `Ctrl-b q` | Show pane numbers briefly (type number to jump) |
| `Ctrl-b z` | Zoom pane to full screen (toggle) |
| `Ctrl-b {` | Swap with previous pane |
| `Ctrl-b }` | Swap with next pane |
| `Ctrl-b x` | Kill current pane |
| `Ctrl-b Ctrl-arrow` | Resize pane in direction |

## Copy Mode

Copy mode lets you scroll up and search within the pane buffer.

| Key | Action |
|-----|--------|
| `Ctrl-b [` | Enter copy mode |
| `q` or `Esc` | Exit copy mode |
| `Space` | Start selection (vi mode) |
| `Enter` | Copy selection |
| `Ctrl-b ]` | Paste copied text |
| `/` | Search forward |
| `?` | Search backward |
| `n` / `N` | Next/previous search result |
| `g` / `G` | Go to top/bottom |

## Configuration (~/.tmux.conf)

```bash
# Change prefix to Ctrl-a (screen-style)
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Enable mouse
set -g mouse on

# Start windows and panes at 1 (not 0)
set -g base-index 1
setw -g pane-base-index 1

# Vi-style copy mode
setw -g mode-keys vi

# Reload config
bind r source-file ~/.tmux.conf \; display "Config reloaded"

# Status bar
set -g status-style "bg=blue fg=white"
set -g window-status-current-style "bold"
```

Apply: `Ctrl-b :source-file ~/.tmux.conf`

## Practical Workflows

```bash
# Start a named session for a project
tmux new -s project

# Split into 3 panes: editor, terminal, logs
Ctrl-b "    # top/bottom split
Ctrl-b %    # split bottom pane left/right

# Long-running job you can detach from
tmux new -s deploy
./deploy.sh
Ctrl-b d    # detach — script keeps running
ssh same-host
tmux attach -t deploy  # check on it

# Shared session (two people, same session)
tmux new -s shared
# From another terminal:
tmux attach -t shared
```

## Further Reading

- [tmux(1) — man7.org](https://man7.org/linux/man-pages/man1/tmux.1.html) — the complete tmux man page: every command, option, status bar format string, hook, and `~/.tmux.conf` directive referenced in this lesson.
- [tmux cheatsheet — tmuxcheatsheet.com](https://tmuxcheatsheet.com/) — single-page reference for all prefix key bindings organized by sessions, windows, panes, and copy mode; useful to keep open during the first few weeks.
- [Arch Wiki — tmux](https://wiki.archlinux.org/title/Tmux) — covers `.tmux.conf` configuration patterns, plugin manager (TPM) setup, clipboard integration, and common issues like the `$TERM` variable and 256-color support.
- [tmux GitHub wiki](https://github.com/tmux/tmux/wiki) — official tmux wiki with FAQ, clipboard/OSC 52 setup, `if-shell` conditionals in configs, and the full option reference for status bars and key bindings.
