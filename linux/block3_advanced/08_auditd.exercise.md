# Exercise: Linux Audit Framework

## Setup

```bash
mkdir -p ~/practice/audit
# Install auditd if not present
sudo apt-get install -y auditd audispd-plugins 2>/dev/null || true
sudo systemctl start auditd 2>/dev/null || true
```

## Task 1: Check Audit System Status

```bash
sudo auditctl -s
```

Note: `enabled` shows 1 (enabled) or 0 (disabled), `backlog` shows queued events.

## Task 2: Add Watch Rules

```bash
# Watch /etc/passwd for any write or attribute change
sudo auditctl -w /etc/passwd -p wa -k practice_passwd

# Watch a temp directory for all access types
mkdir -p ~/practice/audit/watched
sudo auditctl -w ~/practice/audit/watched -p rwxa -k practice_dir

# Verify rules are loaded
sudo auditctl -l
```

## Task 3: Trigger Audit Events

```bash
# Trigger the /etc/passwd watch (read it)
cat /etc/passwd > /dev/null

# Trigger the directory watch
touch ~/practice/audit/watched/testfile.txt
echo "content" > ~/practice/audit/watched/testfile.txt
cat ~/practice/audit/watched/testfile.txt
```

## Task 4: Search the Audit Log

```bash
# Find all events tagged with our key
sudo ausearch -k practice_passwd -i 2>/dev/null || \
    echo "Note: may need a moment for auditd to flush"

# Find events for the watched directory
sudo ausearch -k practice_dir -i 2>/dev/null | tail -30

# Search for events in the last 10 minutes
sudo ausearch -ts recent -i 2>/dev/null | tail -20
```

## Task 5: Generate a Report

```bash
# Overall summary
sudo aureport 2>/dev/null | head -30

# Failed events (if any)
sudo aureport --failed 2>/dev/null | head -20

# Executable report
sudo aureport -x --summary 2>/dev/null | head -20
```

## Task 6: Write a Persistent Rule File

```bash
cat > ~/practice/audit/my_rules.rules << 'EOF'
# Baseline audit rules for the practice environment
-D
-b 4096
-f 1

# Identity-related files
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity

# Sudo usage
-w /usr/bin/sudo -p x -k sudo_use

# Watched practice directory
-w /root/practice/audit/watched -p rwxa -k practice_watch
EOF

cat ~/practice/audit/my_rules.rules
echo "Rules written. In production: sudo cp my_rules.rules /etc/audit/rules.d/ && sudo augenrules --load"
```

## Task 7: Search for Your Own Activity

```bash
# Find your UID
MY_UID=$(id -u)
echo "My UID: $MY_UID"

# Search for audit events associated with your UID
sudo ausearch -ui $MY_UID -ts recent -i 2>/dev/null | tail -30

# Clean up test rules
sudo auditctl -W /etc/passwd -p wa -k practice_passwd 2>/dev/null || true
sudo auditctl -W ~/practice/audit/watched -p rwxa -k practice_dir 2>/dev/null || true
```

## Expected Outcome

- `auditd` is installed and running
- `auditctl -l` shows audit rules
- `ausearch -k practice_dir` finds events from touching files in the watched directory
- `aureport` produces a summary of audit activity
- `~/practice/audit/my_rules.rules` contains a valid audit ruleset
