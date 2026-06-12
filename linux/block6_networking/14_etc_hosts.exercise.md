# Exercise: /etc/hosts and Name Resolution

## Tasks

1. **Read the current state**: Examine the full name resolution stack:
   ```bash
   {
     echo "=== /etc/hosts ==="
     cat /etc/hosts
     echo ""
     echo "=== nsswitch.conf hosts line ==="
     grep "^hosts" /etc/nsswitch.conf
     echo ""
     echo "=== /etc/resolv.conf ==="
     cat /etc/resolv.conf
   } > ~/practice/hosts_inventory.txt
   ```

2. **Add and test a hosts entry**: Add a custom entry, verify it resolves, then clean up:
   ```bash
   # Add entry
   echo "127.0.0.1 linux-study-test.local" | sudo tee -a /etc/hosts
   
   # Verify it resolves via /etc/hosts
   getent hosts linux-study-test.local > ~/practice/hosts_getent.txt
   ping -c1 linux-study-test.local -W1 >> ~/practice/hosts_getent.txt 2>&1 || true
   
   # Confirm it's in the file
   grep linux-study-test.local /etc/hosts >> ~/practice/hosts_getent.txt
   
   # Clean up
   sudo sed -i '/linux-study-test.local/d' /etc/hosts
   ```

3. **getent comparison**: Compare /etc/hosts lookup vs DNS lookup for a real hostname:
   ```bash
   {
     echo "=== via files only ==="
     getent -s files hosts localhost
     echo "=== via full NSS ==="
     getent hosts localhost
     echo "=== dig (DNS only, bypass hosts) ==="
     dig +short localhost @127.0.0.1 2>/dev/null || echo "(dig returned nothing for localhost - expected, localhost is in /etc/hosts only)"
   } > ~/practice/hosts_comparison.txt
   ```

4. **Write hosts entries**: Write `~/practice/hosts_examples.txt` with valid `/etc/hosts` entries for:
   - Blocking a tracker (`0.0.0.0 ads.tracker.example.com`)
   - A local dev override (`127.0.0.1 api.myapp.local`)
   - An internal service with an alias (`10.0.0.10 db.internal db`)
   - An IPv6 loopback entry

5. **resolv.conf analysis**: Document what each directive in `/etc/resolv.conf` does:
   ```bash
   {
     echo "Current /etc/resolv.conf:"
     cat /etc/resolv.conf
     echo ""
     echo "Explanation:"
     echo "nameserver: IP of DNS server to query"
     echo "search: domain(s) appended to short names"
     echo "options ndots: names with fewer dots than this get search appended"
     resolvectl status 2>/dev/null | head -20 || echo "(systemd-resolved not running)"
   } > ~/practice/resolv_explained.txt
   ```

## Hints

- `getent hosts` uses the full NSS stack (files + DNS in order from nsswitch.conf)
- `getent -s files hosts` forces only `/etc/hosts` lookup — useful for testing without DNS
- `dig hostname @server` queries a specific DNS server directly, bypassing local resolver
- The `0.0.0.0` trick for blocking domains works because connections to 0.0.0.0 fail immediately
