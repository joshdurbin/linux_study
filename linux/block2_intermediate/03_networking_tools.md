# Networking Tools

Network troubleshooting is a critical skill. These tools let you test connectivity, inspect traffic, query DNS, and understand what services are listening.

## ping — Test Connectivity

```bash
ping google.com              # send ICMP echo requests (Ctrl-C to stop)
ping -c 4 8.8.8.8            # send exactly 4 packets
ping -i 2 host               # 2 second interval between packets
ping -W 1 host               # 1 second timeout per packet
ping6 ::1                    # IPv6 ping
```

`ping` measures round-trip time and packet loss. No response can mean host down, firewall blocking ICMP, or route problem.

## curl — Transfer Data via URLs

```bash
curl https://example.com             # GET request, print to stdout
curl -o output.html https://...      # save to file
curl -O https://host/file.tar.gz     # save with original filename
curl -I https://example.com          # HEAD request: headers only
curl -i https://example.com          # response headers + body
curl -v https://example.com          # verbose: show full transaction
curl -L https://...                  # follow redirects
curl -s https://...                  # silent (no progress bar)
curl -f https://...                  # fail with non-zero exit on HTTP errors

# POST
curl -X POST -d '{"key":"val"}' -H 'Content-Type: application/json' URL
curl -X POST -F 'file=@/path/to/file' URL

# With authentication
curl -u user:pass https://api.example.com
curl -H 'Authorization: Bearer TOKEN' https://api.example.com

# Show just HTTP status code
curl -o /dev/null -s -w "%{http_code}\n" https://example.com
```

## wget — Download Files

```bash
wget https://example.com/file.tar.gz    # download to current dir
wget -O output.tar.gz URL               # specify output filename
wget -q URL                             # quiet (no progress)
wget -c URL                             # resume interrupted download
wget --limit-rate=1m URL                # throttle to 1 MB/s
wget -r -l 2 https://site.com/          # recursive mirror, depth 2
```

## ss — Socket Statistics (modern netstat)

```bash
ss -tuln                    # listening TCP/UDP ports (no DNS lookup)
ss -tulnp                   # same + process info (run as root)
ss -s                       # socket statistics summary
ss -ta                      # all TCP sockets (established + listen)
ss -tp                      # TCP + process info
ss dst 192.168.1.1          # connections to specific IP
ss sport = :80              # connections on source port 80
```

Columns: `State  Recv-Q  Send-Q  Local  Peer  Process`

## ip — Network Interface Management

```bash
ip addr                     # all interfaces and addresses
ip addr show eth0           # specific interface
ip addr show | grep "inet " # just IPv4 addresses
ip link                     # link-layer info (MAC, state)
ip route                    # routing table
ip route get 8.8.8.8        # which route would be used?
ip -4 addr                  # IPv4 only
ip -6 addr                  # IPv6 only
```

## traceroute — Trace the Path

```bash
traceroute google.com       # show hops to destination
traceroute -n google.com    # numeric (skip DNS lookups)
traceroute -T google.com    # use TCP SYN instead of UDP
mtr google.com              # real-time combined ping+traceroute
```

## dig and nslookup — DNS Queries

```bash
dig google.com              # query A records
dig google.com MX           # query mail records
dig google.com ANY          # all record types
dig @8.8.8.8 google.com     # use specific DNS server
dig +short google.com       # just the answer, no fluff
dig -x 8.8.8.8              # reverse lookup (PTR record)

nslookup google.com         # interactive DNS lookup
nslookup google.com 8.8.8.8 # use specific DNS server
```

## ssh — Secure Shell

```bash
ssh user@host               # connect to remote host
ssh -p 2222 user@host       # non-standard port
ssh -i ~/.ssh/id_rsa user@host  # specific key
ssh -L 8080:localhost:80 user@host  # local port forward
ssh -N -L 5432:db-host:5432 jump   # tunnel: no shell, just forward
ssh -o StrictHostKeyChecking=no user@host  # skip host key check (careful!)
```

Key files: `~/.ssh/id_rsa` (private), `~/.ssh/id_rsa.pub` (public), `~/.ssh/authorized_keys` (on server), `~/.ssh/known_hosts` (trusted hosts).

## Further Reading

- [man7.org — ip(8)](https://man7.org/linux/man-pages/man8/ip.8.html) — Full reference for the `ip` command suite: `addr`, `link`, `route`, `neigh`, `rule`, and `netns` subcommands.
- [OpenSSH Manual Pages](https://man.openbsd.org/ssh) — Authoritative documentation for `ssh`, `ssh-keygen`, `ssh-agent`, and `scp` from the OpenSSH project.
- [curl Manual](https://curl.se/docs/manpage.html) — Complete curl option reference including all protocol flags, authentication methods, and the `--write-out` format specifiers.
- [Julia Evans — Send Network Packets](https://jvns.ca/blog/2022/09/06/send-network-packets/) — Practical guide to sending raw packets with various tools, building intuition for how `ping`, `curl`, and `nc` work at the socket level.
- [Arch Wiki — Network configuration](https://wiki.archlinux.org/title/Network_configuration) — Covers interface naming, `ip` commands, DNS resolution, and static configuration — good reference for diagnosing connectivity issues.
