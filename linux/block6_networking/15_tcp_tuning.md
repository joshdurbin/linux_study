# TCP Tuning

TCP's default settings are conservative and optimized for general use across diverse network conditions. Production systems — especially high-throughput or low-latency services — require deliberate tuning. All tuning is done via `sysctl` (block5/02) on live TCP socket parameters.

## The TCP Receive Path and Buffers

```
NIC → ring buffer → softirq → socket receive buffer → application read()
```

When the socket receive buffer fills faster than the application reads, the kernel drops incoming packets. When the send buffer fills faster than ACKs come back (congestion), the sender stalls.

```bash
# Default receive and send buffer sizes
sysctl net.core.rmem_default      # receive buffer default (bytes)
sysctl net.core.rmem_max          # receive buffer maximum
sysctl net.core.wmem_default
sysctl net.core.wmem_max

# TCP-specific auto-tuning buffer sizes (min, default, max)
sysctl net.ipv4.tcp_rmem          # e.g.: 4096  131072  6291456
sysctl net.ipv4.tcp_wmem

# Enable auto-tuning (on by default)
sysctl net.ipv4.tcp_moderate_rcvbuf   # 1 = auto-tune between tcp_rmem min/max

# Tune for high-throughput (e.g., 10G+ networks)
sudo sysctl -w net.core.rmem_max=134217728         # 128MB
sudo sysctl -w net.core.wmem_max=134217728
sudo sysctl -w net.ipv4.tcp_rmem="4096 87380 134217728"
sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 134217728"
```

## Congestion Control

TCP congestion control manages how fast to send when the network is saturated. The algorithm is pluggable in Linux.

```bash
# View current congestion control algorithm
sysctl net.ipv4.tcp_congestion_control   # usually: cubic

# List available algorithms
sysctl net.ipv4.tcp_available_congestion_control
# output: reno cubic bbr (bbr requires separate load)

# Switch to BBR (Google's algorithm — better for high-BDP or lossy links)
sudo modprobe tcp_bbr
sudo sysctl -w net.ipv4.tcp_congestion_control=bbr

# Verify
sysctl net.ipv4.tcp_congestion_control
```

**CUBIC** (default): delay-based, backs off on packet loss. Works well on most links.
**BBR**: models bottleneck bandwidth and RTT; sends at the estimated optimal rate regardless of packet loss signals. Better for long fat networks (satellite, WAN) and links with shallow buffers.

## TIME_WAIT — Handling Lots of Short Connections

After a connection closes, the socket stays in `TIME_WAIT` for `2*MSL` (Maximum Segment Lifetime, default 60s) to absorb delayed duplicate packets. High-volume services (HTTP APIs) generate thousands of TIME_WAIT sockets.

```bash
# See TIME_WAIT socket count (ss from block6/05)
ss -ant state time-wait | wc -l

# Important: TIME_WAIT is normal and generally harmless.
# It only becomes a problem when you exhaust the local port range.

# View port range
sysctl net.ipv4.ip_local_port_range   # e.g.: 32768  60999  (28231 ports)

# Widen the ephemeral port range
sudo sysctl -w net.ipv4.ip_local_port_range="1024 65535"

# Allow reuse of TIME_WAIT sockets for new connections from the same 4-tuple
sysctl net.ipv4.tcp_tw_reuse   # 1 = enabled (safe for outbound connections)
sudo sysctl -w net.ipv4.tcp_tw_reuse=1
```

Do NOT set `tcp_tw_recycle` (removed in kernel 4.12) — it broke NAT environments.

## TCP Keepalive

Keepalive probes detect dead connections. Without them, a connection to an idle peer can stay open indefinitely even after the peer crashes.

```bash
# Time after last data before sending keepalive probes
sysctl net.ipv4.tcp_keepalive_time       # default: 7200 seconds (2 hours!)

# Interval between probes
sysctl net.ipv4.tcp_keepalive_intvl      # default: 75 seconds

# Number of probes before declaring connection dead
sysctl net.ipv4.tcp_keepalive_probes     # default: 9

# Tune for faster dead connection detection (e.g., 60s total)
sudo sysctl -w net.ipv4.tcp_keepalive_time=60
sudo sysctl -w net.ipv4.tcp_keepalive_intvl=10
sudo sysctl -w net.ipv4.tcp_keepalive_probes=6
# Worst case: 60s + (6 × 10s) = 120s to detect dead connection
```

## SYN Backlog and Connection Queues

```bash
# SYN backlog: half-open connections waiting to complete handshake
sysctl net.ipv4.tcp_max_syn_backlog      # default: 512 or 1024

# Listen backlog: fully-established connections waiting for accept()
# Set by the application (listen(fd, backlog)) and bounded by:
sysctl net.core.somaxconn                # default: 4096

# For high-connection-rate services
sudo sysctl -w net.ipv4.tcp_max_syn_backlog=4096
sudo sysctl -w net.core.somaxconn=4096

# SYN cookies: protect against SYN flood (on by default on modern kernels)
sysctl net.ipv4.tcp_syncookies           # should be 1
```

## Retransmission Tuning

```bash
# Retransmit timeout ranges (milliseconds)
sysctl net.ipv4.tcp_rto_min_us          # minimum RTO in microseconds
# Default: 200000 (200ms) — can cause long pauses after packet loss

# Number of retransmits before considering path broken
sysctl net.ipv4.tcp_retries2            # default: 15 (~13-30 minutes!)

# For faster failure detection in data centers (known low-latency paths)
sudo sysctl -w net.ipv4.tcp_retries2=5  # ~6-12 seconds before giving up
```

## tcp_nodelay and Nagle's Algorithm

Nagle's algorithm batches small writes to reduce packet count. It causes up to 40ms latency for streaming small messages.

```bash
# Nagle is controlled per-socket: TCP_NODELAY option
# Cannot be set globally — must be set by the application

# Check if a service has Nagle disabled
ss -ti dst :6379 2>/dev/null | grep -i nagle   # check Redis connections
# "cubic..." output — look for "ts sack cubic wscale" indicating nagle state

# Verify Nagle state for sockets on a port
ss -tino sport :8080 | grep -E "cubic|nagle"
```

## Persistent Tuning

```bash
# Make settings permanent in /etc/sysctl.d/
sudo tee /etc/sysctl.d/99-tcp-tuning.conf << 'EOF'
# TCP buffer auto-tuning
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728

# Faster keepalive
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6

# TIME_WAIT reuse
net.ipv4.tcp_tw_reuse = 1

# Listen backlog
net.core.somaxconn = 4096
net.ipv4.tcp_max_syn_backlog = 4096
EOF

sudo sysctl -p /etc/sysctl.d/99-tcp-tuning.conf
```

## Further Reading

- [tcp(7) man page](https://man7.org/linux/man-pages/man7/tcp.7.html) — The definitive sysctl reference for every TCP parameter (`tcp_rmem`, `tcp_wmem`, `tcp_keepalive_time`, `tcp_tw_reuse`, `somaxconn`) and socket options (`TCP_NODELAY`, `TCP_CORK`, `TCP_KEEPIDLE`) covered in this lesson.
- [RFC 5681 — TCP Congestion Control](https://datatracker.ietf.org/doc/html/rfc5681) — The specification for TCP's slow start, congestion avoidance, and fast retransmit algorithms that CUBIC and BBR are built on top of.
- [BBR: Congestion-Based Congestion Control](https://research.google/pubs/pub45646/) — Google's original BBR paper explaining the model-based approach and why it outperforms loss-based algorithms like CUBIC on high-BDP and lossy networks.
- [Cloudflare: This is fine — optimizing the Linux kernel](https://blog.cloudflare.com/this-is-fine-optimizing-the-linux-kernel/) — Cloudflare's in-depth post on TIME_WAIT at scale, covering `tcp_tw_reuse`, ephemeral port ranges, and why `tcp_tw_recycle` was removed — directly relevant to the TIME_WAIT section of this lesson.
