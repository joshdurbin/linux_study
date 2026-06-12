# Exercise: nftables and ufw

## Setup

```bash
mkdir -p ~/practice
sudo apt-get install -y ufw nftables 2>/dev/null || true
```

## Task 1: Check Current Firewall State

```bash
echo "=== ufw status ==="
sudo ufw status 2>/dev/null

echo ""
echo "=== iptables rules ==="
sudo iptables -L -n -v 2>/dev/null | head -30

echo ""
echo "=== nft ruleset ==="
sudo nft list ruleset 2>/dev/null | head -30
```

## Task 2: Examine iptables Chains

```bash
# List INPUT chain rules
sudo iptables -L INPUT -n -v

# List all chains with packet counts
sudo iptables -L -n -v

# Check the NAT table
sudo iptables -t nat -L -n
```

## Task 3: Add and Remove a ufw Rule

```bash
# Check initial status
sudo ufw status

# Add a rule to allow port 9999
sudo ufw allow 9999/tcp

# Verify it was added
sudo ufw status | grep 9999

# Remove the rule
sudo ufw delete allow 9999/tcp

# Verify it was removed
sudo ufw status | grep 9999 || echo "Rule successfully removed"
```

## Task 4: List iptables Rules with Line Numbers

```bash
# View rules with numbers (useful for deletion)
sudo iptables -L INPUT -n --line-numbers
sudo iptables -L OUTPUT -n --line-numbers
```

## Task 5: View nftables Ruleset

```bash
# Full nft ruleset
sudo nft list ruleset 2>/dev/null || echo "nftables: no rules or not available"

# List tables
sudo nft list tables 2>/dev/null
```

## Task 6: Document Firewall Findings

```bash
cat > ~/practice/firewall_notes.txt << 'EOF'
Linux Firewall Quick Reference
==============================

Tools:
  ufw     - Easy frontend, Ubuntu default
  nft     - Modern nftables CLI (replaces iptables)
  iptables - Classic, still widely used

ufw commands:
  sudo ufw status [verbose|numbered]
  sudo ufw enable / disable
  sudo ufw allow 22/tcp
  sudo ufw allow from 10.0.0.0/8
  sudo ufw deny 23/tcp
  sudo ufw delete allow 22/tcp
  sudo ufw default deny incoming

iptables commands:
  sudo iptables -L -n -v            # list all rules
  sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
  sudo iptables -D INPUT 3          # delete rule #3
  sudo iptables -F                  # flush all rules
  sudo iptables -P INPUT DROP       # default policy

nftables commands:
  sudo nft list ruleset
  sudo nft list tables
  sudo nft add rule inet filter input tcp dport 80 accept

Netfilter hooks:
  PREROUTING → INPUT/FORWARD → POSTROUTING/OUTPUT

Targets:
  ACCEPT - allow the packet
  DROP   - silently discard
  REJECT - discard and notify sender
  LOG    - log to kernel log
EOF

# Append current state
echo "" >> ~/practice/firewall_notes.txt
echo "Current ufw status:" >> ~/practice/firewall_notes.txt
sudo ufw status 2>/dev/null >> ~/practice/firewall_notes.txt

cat ~/practice/firewall_notes.txt
```

## Expected Outcome

- `~/practice/firewall_notes.txt` exists
- You can check ufw status, add/remove rules, and list iptables chains
- You understand the relationship between ufw, iptables, and nftables
