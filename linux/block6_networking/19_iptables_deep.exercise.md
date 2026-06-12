# Exercise: iptables Deep Dive

Work through these tasks inside your Linux study container. You will need root privileges for all iptables commands.

---

## Setup

```bash
mkdir -p ~/practice/iptables
cd ~/practice/iptables
```

Check which iptables backend is active (the container may use iptables-legacy):

```bash
which iptables
iptables --version
# If iptables-nft, also try:
which iptables-legacy 2>/dev/null && iptables-legacy --version
```

---

## Task 1 — List All Current Rules with Verbose Counts

List the rules in every built-in table with packet and byte counters. Use the numeric flag to avoid DNS lookups.

```bash
# filter table (default)
iptables -t filter -L -v -n

# nat table
iptables -t nat -L -v -n

# mangle table
iptables -t mangle -L -v -n

# raw table
iptables -t raw -L -v -n
```

Observe:
- Which chains exist in each table
- The default policy for INPUT, FORWARD, OUTPUT
- Any pre-existing rules (e.g., from Docker or the container runtime)

Save a snapshot of the initial state:

```bash
iptables-save > ~/practice/iptables/initial_rules.v4
cat ~/practice/iptables/initial_rules.v4
```

---

## Task 2 — Add and Test a DROP Rule on Loopback

Add a rule to drop TCP packets to port 19999 on loopback. Then verify it blocks traffic.

```bash
# Add the DROP rule
iptables -A INPUT -i lo -p tcp --dport 19999 -j DROP

# Verify the rule appears
iptables -L INPUT -v -n --line-numbers

# Attempt to connect (should timeout/refuse) — start a listener in background
nc -l -p 19999 &
BGPID=$!
# Try to connect — nc should fail immediately (port unreachable or timeout)
nc -w 2 127.0.0.1 19999 && echo "CONNECTED (unexpected)" || echo "BLOCKED (expected)"
kill $BGPID 2>/dev/null

# Remove the rule
iptables -D INPUT -i lo -p tcp --dport 19999 -j DROP

# Confirm it's gone
iptables -L INPUT -v -n --line-numbers
```

---

## Task 3 — Add a LOG Rule

Add a LOG rule to capture packets hitting a specific port, then generate some traffic to trigger it.

```bash
# Add LOG rule for port 29999
iptables -A INPUT -i lo -p tcp --dport 29999 \
  -j LOG --log-prefix "STUDY-LOG: " --log-level 4

# Generate a packet (connect attempt)
nc -w 1 127.0.0.1 29999 2>/dev/null || true

# Check kernel log for the entry
dmesg | tail -20 | grep STUDY-LOG || \
  journalctl -k --no-pager -n 20 | grep STUDY-LOG || \
  echo "Log entry may be in journald — try: journalctl -k | grep STUDY-LOG"

# Clean up
iptables -D INPUT -i lo -p tcp --dport 29999 \
  -j LOG --log-prefix "STUDY-LOG: " --log-level 4
```

---

## Task 4 — Save Rules with iptables-save

Explore the iptables-save output format.

```bash
# Add some test rules to inspect in save format
iptables -A INPUT -i lo -p tcp --dport 18080 -j ACCEPT
iptables -A INPUT -i lo -p udp --dport 18053 -j DROP
iptables -t nat -A OUTPUT -p tcp --dport 18888 -j REDIRECT --to-port 18889

# Save to file and examine
iptables-save > ~/practice/iptables/test_rules.v4
cat ~/practice/iptables/test_rules.v4

# Point out:
# - *filter / *nat sections
# - :CHAIN POLICY [packets:bytes]
# - -A rules in restore format
# - COMMIT terminator

# Save only the filter table
iptables-save -t filter > ~/practice/iptables/filter_only.v4
cat ~/practice/iptables/filter_only.v4

# Clean up test rules
iptables -D INPUT -i lo -p tcp --dport 18080 -j ACCEPT
iptables -D INPUT -i lo -p udp --dport 18053 -j DROP
iptables -t nat -D OUTPUT -p tcp --dport 18888 -j REDIRECT --to-port 18889
```

---

## Task 5 — iptables-restore Round-Trip

Practice the save/restore workflow.

```bash
# Save current state
iptables-save > ~/practice/iptables/before_restore.v4

# Add a canary rule
iptables -A INPUT -i lo -p tcp --dport 17777 -j DROP
iptables -L INPUT -v -n | grep 17777   # confirm it's there

# Restore the saved state (this removes the canary)
iptables-restore < ~/practice/iptables/before_restore.v4

# Canary should be gone
iptables -L INPUT -v -n | grep 17777 && echo "Rule still present!" \
  || echo "Restore successful — rule removed"
```

---

## Task 6 — Packet/Byte Counter Script

Write a script that displays total packet and byte counts across all chains in the filter table.

```bash
cat > ~/practice/iptables/count_totals.sh << 'EOF'
#!/bin/bash
# count_totals.sh — summarise packet/byte counts for all filter chains

echo "=== iptables filter table: packet/byte counts ==="
echo ""

TOTAL_PKTS=0
TOTAL_BYTES=0

while IFS= read -r line; do
    # Match lines like: "Chain INPUT (policy ACCEPT 1234 packets, 567890 bytes)"
    if [[ "$line" =~ ^Chain.*([0-9]+)\ packets,\ ([0-9]+)\ bytes ]]; then
        CHAIN_NAME=$(echo "$line" | awk '{print $2}')
        PKTS="${BASH_REMATCH[1]}"
        BYTES="${BASH_REMATCH[2]}"
        printf "  %-20s %10d packets  %12d bytes\n" "$CHAIN_NAME" "$PKTS" "$BYTES"
        TOTAL_PKTS=$((TOTAL_PKTS + PKTS))
        TOTAL_BYTES=$((TOTAL_BYTES + BYTES))
    fi
done < <(iptables -L -v -n 2>/dev/null)

echo ""
printf "  %-20s %10d packets  %12d bytes\n" "TOTAL" "$TOTAL_PKTS" "$TOTAL_BYTES"
echo ""
echo "Rules in filter table: $(iptables -L -v -n | grep -c '^[[:space:]]*[0-9]')"
EOF

chmod +x ~/practice/iptables/count_totals.sh
bash ~/practice/iptables/count_totals.sh
```

---

## Task 7 — Inspect Docker Rules (Optional)

If Docker is running, examine the rules it has created:

```bash
# Show only Docker-related rules
iptables-save | grep -i docker

# Count Docker rules
iptables-save | grep -i docker | wc -l

# Show the DOCKER-USER chain (safe place to add custom rules on Docker hosts)
iptables -L DOCKER-USER -v -n 2>/dev/null || echo "DOCKER-USER chain not present"

# Show NAT masquerade rule for Docker bridge
iptables -t nat -L POSTROUTING -v -n | grep 172.17 || echo "No Docker bridge NAT rule"
```

---

## Task 8 — Create a User-Defined Chain

Practice creating, using, and removing a custom chain:

```bash
# Create chain
iptables -N STUDY_CHAIN

# Add a rule to the chain
iptables -A STUDY_CHAIN -p tcp --dport 16666 -j DROP
iptables -A STUDY_CHAIN -j RETURN   # fall through for everything else

# Reference it from INPUT
iptables -A INPUT -i lo -j STUDY_CHAIN

# Verify
iptables -L -v -n --line-numbers | grep -A5 STUDY_CHAIN

# Test it (should be blocked)
nc -w 1 127.0.0.1 16666 2>/dev/null && echo "connected" || echo "blocked"

# Clean up — must remove references before deleting chain
LINE=$(iptables -L INPUT --line-numbers | grep STUDY_CHAIN | awk '{print $1}')
iptables -D INPUT $LINE
iptables -F STUDY_CHAIN
iptables -X STUDY_CHAIN

# Verify removal
iptables -L -v -n | grep STUDY_CHAIN && echo "Chain still exists!" || echo "Chain removed"
```

---

## Verification

```bash
# Confirm key files exist
ls -la ~/practice/iptables/

# Run your counter script one more time
bash ~/practice/iptables/count_totals.sh

# Show final rule state
iptables -L -v -n
```
