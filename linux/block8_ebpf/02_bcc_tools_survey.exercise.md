# BCC Tools Survey — Exercises

> **Container note:** BCC tools require a privileged container and kernel headers matching the running kernel. If unavailable, complete the documentation tasks.

Complete these tasks. Record findings in `~/practice/bcc_survey.txt`.

## Setup

```bash
mkdir -p ~/practice
```

## Task 1 — Check BCC availability

```bash
echo "=== BCC tools availability ===" >> ~/practice/bcc_survey.txt

# Check multiple possible install locations
for tool in opensnoop execsnoop biolatency tcpconnect; do
    if command -v "${tool}-bpfcc" &>/dev/null; then
        echo "FOUND: ${tool}-bpfcc" >> ~/practice/bcc_survey.txt
    elif command -v "$tool" &>/dev/null; then
        echo "FOUND: $tool" >> ~/practice/bcc_survey.txt
    else
        echo "NOT FOUND: $tool" >> ~/practice/bcc_survey.txt
    fi
done

ls /usr/share/bcc/tools/ 2>/dev/null | head -20 >> ~/practice/bcc_survey.txt \
    || echo "BCC tools directory not found" >> ~/practice/bcc_survey.txt
```

## Task 2 — Run opensnoop (if available), otherwise document

```bash
echo "=== opensnoop (file opens) ===" >> ~/practice/bcc_survey.txt
if command -v opensnoop-bpfcc &>/dev/null; then
    echo "Running opensnoop for 5 seconds..." >> ~/practice/bcc_survey.txt
    sudo timeout 5 opensnoop-bpfcc 2>> ~/practice/bcc_survey.txt || true
elif command -v opensnoop &>/dev/null; then
    sudo timeout 5 opensnoop 2>> ~/practice/bcc_survey.txt || true
else
    cat >> ~/practice/bcc_survey.txt << 'EOF'
opensnoop not available.
What it would show:
  PID   COMM         FD ERR PATH
  1234  nginx         4   0 /var/log/nginx/access.log
  1235  sshd          3   0 /etc/ssh/sshd_config

opensnoop attaches kprobes to do_sys_open/do_sys_openat2 and prints
every file open with the opening process name, FD, error code, and path.
Use case: finding which files a process opens, debugging ENOENT errors.
EOF
fi
```

## Task 3 — Run biolatency (if available), otherwise document

```bash
echo "=== biolatency (block I/O latency) ===" >> ~/practice/bcc_survey.txt
if command -v biolatency-bpfcc &>/dev/null; then
    echo "Running biolatency for 5 seconds..." >> ~/practice/bcc_survey.txt
    sudo timeout 5 biolatency-bpfcc 2>> ~/practice/bcc_survey.txt || true
else
    cat >> ~/practice/bcc_survey.txt << 'EOF'
biolatency not available.
What it would show (power-of-2 histogram of I/O latency):
     usecs               : count     distribution
         0 -> 1          : 0        |                    |
         2 -> 3          : 0        |                    |
         4 -> 7          : 2        |                    |
         8 -> 15         : 6        |**                  |
        16 -> 31         : 52       |********************|
        32 -> 63         : 28       |***********         |
       128 -> 255        : 3        |*                   |

biolatency attaches kprobes to blk_account_io_start/done and records
the latency distribution. Outliers in the tail reveal intermittent slowness.
EOF
fi
```

## Task 4 — Run tcpconnect (if available), otherwise document

```bash
echo "=== tcpconnect (outbound TCP) ===" >> ~/practice/bcc_survey.txt
if command -v tcpconnect-bpfcc &>/dev/null; then
    echo "Running tcpconnect for 5 seconds (make some connections)..." >> ~/practice/bcc_survey.txt
    (sudo timeout 5 tcpconnect-bpfcc 2>> ~/practice/bcc_survey.txt &
     sleep 1; curl -s http://example.com > /dev/null 2>&1 || true
     wait) 2>/dev/null || true
else
    cat >> ~/practice/bcc_survey.txt << 'EOF'
tcpconnect not available.
What it would show:
  PID   COMM         IP SADDR           DADDR           DPORT
  1234  curl          4 10.0.0.5        93.184.216.34   80
  1235  ssh           4 192.168.1.10    192.168.1.1     22

tcpconnect attaches kprobes to tcp_v4_connect and tcp_v6_connect.
Use case: auditing outbound connections, detecting unexpected network calls.
EOF
fi
```

## Task 5 — BCC tool comparison table

```bash
cat >> ~/practice/bcc_survey.txt << 'EOF'

=== BCC Tools Quick Reference ===
TOOL           WHAT IT ANSWERS                       OVERHEAD
execsnoop      Which new processes are starting?     Very low
opensnoop      Which files are being opened?         Low
bashreadline   What commands are users typing?       Very low
profile        Where is CPU time being spent?        Low (sampling)
runqlat        How long do tasks wait for CPU?       Low
cpudist        How long do tasks run on CPU?         Low
memleak        Which allocations are never freed?    Medium
slabratetop    Which kernel caches allocate most?    Low
biolatency     What is the I/O latency distribution? Low
biotop         Which processes do the most I/O?      Low
fileslower     Which file ops are slow (>N ms)?      Low
cachestat      What is the page cache hit rate?      Very low
tcpconnect     Who is making outbound connections?   Very low
tcpaccept      Who is connecting to us?              Very low
tcplife        How long do TCP sessions last?        Low
tcpretrans     Are there TCP retransmissions?        Very low
EOF
```

## Verification

```bash
cat ~/practice/bcc_survey.txt | wc -l
echo "Lines in bcc_survey.txt (should be > 20)"
```
