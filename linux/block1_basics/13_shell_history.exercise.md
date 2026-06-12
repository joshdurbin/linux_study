# Exercise: Shell History

## Setup

```bash
mkdir -p ~/practice/history
```

## Task 1: View and Search History

```bash
# View the last 15 commands
history 15

# Search history for a specific term using grep
history | grep "ls"

# Count how many times you've used ls
history | grep -c "ls"
```

## Task 2: Recall Commands by Number

```bash
# Find a command in your history
history | grep "mkdir"

# Note its line number (e.g., 42) and recall it with !n
# (replace 42 with the actual number you see)
echo "Would run: $(history | grep "mkdir" | tail -1 | awk '{print $1}')"
```

## Task 3: Last-Argument Recall

```bash
# Create a file path to work with
touch ~/practice/history/testfile.txt

# Now use !$ to reuse that path
ls -la ~/practice/history/testfile.txt
cat !$    # cat ~/practice/history/testfile.txt

# Use Alt-. to insert last argument interactively (press it multiple times)
# (try in the terminal — it cycles through last-args of previous commands)
```

## Task 4: Configure History Variables

Add these settings to your current session and verify them:

```bash
# Set a larger history size
HISTSIZE=50000
HISTFILESIZE=100000

# Enable timestamps
HISTTIMEFORMAT="%F %T "

# Don't record duplicate or space-prefixed commands
HISTCONTROL=ignoreboth

# Verify the settings took effect
echo "HISTSIZE: $HISTSIZE"
echo "HISTFILESIZE: $HISTFILESIZE"
echo "HISTTIMEFORMAT: $HISTTIMEFORMAT"
echo "HISTCONTROL: $HISTCONTROL"
```

## Task 5: Append to History File

```bash
# Enable append mode so multiple sessions don't clobber each other
shopt -s histappend

# Write current session history to disk immediately
history -w

# Verify the history file exists and has content
wc -l ~/.bash_history
```

## Task 6: Delete a History Entry

```bash
# Add a "secret" command to history (it will still be recorded here since
# we haven't set HISTCONTROL yet for this session)
echo "this should be deleted"

# View recent history to find its number
history 5

# Delete the most recent entry (replace N with the actual line number)
LAST=$(history 1 | awk '{print $1}')
history -d $LAST
echo "Deleted entry $LAST"
history 5
```

## Task 7: Space-Prefix to Skip Recording

```bash
# Prefix with a space to avoid recording (requires HISTCONTROL=ignorespace or ignoreboth)
HISTCONTROL=ignoreboth

# This next command will NOT appear in history (leading space)
 echo "this will not be recorded"

# Verify by checking recent history
history 5 | grep "will not be recorded" && echo "OOPS: it was recorded" || echo "Good: not in history"
```

## Task 8: Write a History Setup Script

```bash
cat > ~/practice/history/histsetup.sh << 'EOF'
#!/bin/bash
# Apply recommended history settings for this session
export HISTSIZE=50000
export HISTFILESIZE=100000
export HISTTIMEFORMAT="%F %T "
export HISTCONTROL=ignoreboth
export HISTIGNORE="ls:ll:history:pwd:exit:cd"
shopt -s histappend
echo "History settings applied."
echo "HISTSIZE=$HISTSIZE, HISTCONTROL=$HISTCONTROL"
EOF
chmod +x ~/practice/history/histsetup.sh
bash ~/practice/history/histsetup.sh
```

## Expected Outcome

- `history` lists numbered commands from the current session
- `HISTSIZE`, `HISTFILESIZE`, `HISTTIMEFORMAT`, `HISTCONTROL` are configurable variables
- `history -w` writes current history to `~/.bash_history`
- `history -d N` removes a specific entry by number
- Leading space skips recording when `HISTCONTROL=ignorespace` or `ignoreboth`
- `~/practice/history/histsetup.sh` sets all recommended history variables
