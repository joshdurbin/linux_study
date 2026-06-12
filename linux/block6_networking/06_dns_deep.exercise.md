# Exercise: DNS Deep Dive

## Setup

```bash
mkdir -p ~/practice
sudo apt-get install -y dnsutils bind9-dnsutils 2>/dev/null || true
which dig || sudo apt-get install -y dnsutils
```

## Task 1: Inspect DNS Configuration Files

```bash
echo "=== /etc/resolv.conf ==="
cat /etc/resolv.conf

echo ""
echo "=== /etc/nsswitch.conf (hosts line) ==="
grep hosts /etc/nsswitch.conf

echo ""
echo "=== /etc/hosts ==="
cat /etc/hosts
```

## Task 2: Basic dig Queries

```bash
# If you have internet access, query a real domain
# If not, query localhost or internal hostnames
dig localhost
dig localhost A +short

# Try to resolve a well-known domain
dig cloudflare.com A +short 2>/dev/null || \
  dig example.com A +short 2>/dev/null || \
  echo "External DNS may not be available in this environment"
```

## Task 3: Query Different Record Types

```bash
# A records (IPv4)
dig +short localhost A
dig +noall +answer +question cloudflare.com A 2>/dev/null || true

# Try MX if internet is available
dig +short cloudflare.com MX 2>/dev/null || echo "No internet access for MX query"

# Reverse lookup of loopback
dig -x 127.0.0.1 +short
```

## Task 4: Query a Specific DNS Server

```bash
# Query Google's DNS (requires internet)
dig @8.8.8.8 cloudflare.com +short 2>/dev/null || \
  echo "Cannot reach 8.8.8.8 (no internet)"

# Query the system resolver
RESOLVER=$(grep '^nameserver' /etc/resolv.conf | head -1 | awk '{print $2}')
echo "System resolver: $RESOLVER"
dig @$RESOLVER localhost +short 2>/dev/null
```

## Task 5: Compare dig vs nslookup

```bash
echo "=== dig output ==="
dig localhost

echo ""
echo "=== nslookup output ==="
nslookup localhost 2>/dev/null || echo "nslookup not available"
```

## Task 6: Save DNS Notes

```bash
cat > ~/practice/dns_notes.txt << 'EOF'
DNS Resolution on Linux
=======================

Resolution order (from /etc/nsswitch.conf):
  hosts: files dns
  → Check /etc/hosts first, then DNS

Configuration files:
  /etc/resolv.conf  - nameserver IPs, search domains
  /etc/hosts        - local hostname overrides
  /etc/nsswitch.conf - lookup order

dig quick reference:
  dig example.com           # A record
  dig example.com MX        # MX record
  dig example.com NS        # Name servers
  dig -x 1.2.3.4            # Reverse PTR lookup
  dig @8.8.8.8 example.com  # Use specific resolver
  dig +short example.com    # Short output only
  dig +trace example.com    # Full delegation trace
  dig +noall +answer example.com  # Answer section only

Record types:
  A     - IPv4 address
  AAAA  - IPv6 address
  CNAME - Alias/canonical name
  MX    - Mail exchange
  NS    - Name server
  TXT   - Text (SPF, DKIM, verification)
  PTR   - Reverse DNS (IP → name)
  SOA   - Zone authority info

TTL: Time To Live (seconds to cache the record)
NXDOMAIN: Domain does not exist (also cached)
EOF

# Append actual resolver info
echo "" >> ~/practice/dns_notes.txt
echo "This system's DNS config:" >> ~/practice/dns_notes.txt
cat /etc/resolv.conf >> ~/practice/dns_notes.txt

cat ~/practice/dns_notes.txt
```

## Expected Outcome

- `~/practice/dns_notes.txt` exists with DNS documentation
- You understand the resolution chain: nsswitch → /etc/hosts → resolv.conf → DNS server
- You can use `dig` to query different record types and specific servers
