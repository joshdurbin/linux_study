# Exercise: tmux

tmux is interactive, so most exercises are performed and verified by their side effects.

## Task 1 — Install and verify tmux

Check that tmux is installed:

```bash
tmux -V   # should print version
```

Save the output to `~/tmuxlab/tmux_version.txt`.

## Task 2 — Session lifecycle

1. Create a new named tmux session: `tmux new -s practice`
2. Inside the session, create a file: `touch ~/tmuxlab/inside_session.txt`
3. Detach from the session: `Ctrl-b d`
4. From outside, verify the session exists: `tmux ls > ~/tmuxlab/session_list.txt`
5. Reattach: `tmux attach -t practice`
6. Kill the session from inside: `Ctrl-b :kill-session`

After all steps, `~/tmuxlab/session_list.txt` should contain `practice`.

## Task 3 — Write a tmux config

Create `~/.tmux.conf` with the following settings:

```
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g history-limit 10000
```

Save it. Then verify it exists and has the `mouse on` line.

## Task 4 — tmux scripting

Write a shell script `~/tmuxlab/setup_session.sh` that:
1. Creates a new detached tmux session named `dev`
2. Sends the command `echo "session ready" > ~/tmuxlab/session_ready.txt` to the session
3. Waits 1 second
4. Kills the session

```bash
#!/bin/bash
tmux new-session -d -s dev
tmux send-keys -t dev "echo 'session ready' > ~/tmuxlab/session_ready.txt" Enter
sleep 1
tmux kill-session -t dev
```

Make it executable and run it. Then check that `~/tmuxlab/session_ready.txt` contains "session ready".
