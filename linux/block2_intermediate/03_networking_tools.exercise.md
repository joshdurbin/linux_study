# Exercise: Networking Tools

## Task 1 — curl requests

Create `~/netlab/`. Use `curl` to fetch the HTTP headers (only headers, not body) from `http://httpbin.org/get` and save to `~/netlab/headers.txt`. 

If the internet is not available in your container, use the local mock instead:
```bash
curl -I http://localhost 2>/dev/null || echo "HTTP/1.1 connection-attempted" > ~/netlab/headers.txt
```

Then check what HTTP status code you get from `http://httpbin.org/status/200`:
```bash
curl -o /dev/null -s -w "%{http_code}\n" http://httpbin.org/status/200 > ~/netlab/status_200.txt
```

## Task 2 — Inspect listening ports

Run `ss -tuln` to see all listening TCP and UDP ports. Save the output to `~/netlab/listening_ports.txt`. Then count how many lines there are (excluding the header) and save to `~/netlab/port_count.txt`.

## Task 3 — Network interfaces

Run `ip addr` and save the full output to `~/netlab/ip_addr.txt`. Then extract just lines containing `inet ` (IPv4 addresses) and save to `~/netlab/ipv4_addrs.txt`.

## Task 4 — DNS lookup

Run `dig +short google.com` and save the output to `~/netlab/google_ips.txt`. If `dig` is not installed, use `nslookup google.com` instead. If neither works (no internet), write `127.0.0.1` to `~/netlab/google_ips.txt` to indicate you attempted the exercise.

Also run `dig +short @8.8.8.8 github.com` (or the nslookup equivalent) and save to `~/netlab/github_ips.txt`.
