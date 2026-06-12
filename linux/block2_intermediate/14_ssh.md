# SSH — Secure Shell Deep Dive

SSH is the standard for secure remote access, file transfer, and tunneling. Mastering its configuration and options saves hours of operational friction.

## Key Generation

```bash
# Ed25519 (recommended — compact, fast, secure)
ssh-keygen -t ed25519 -C "your@email.com"

# RSA 4096 (compatibility with older systems)
ssh-keygen -t rsa -b 4096

# Output:
# ~/.ssh/id_ed25519      — private key (protect this)
# ~/.ssh/id_ed25519.pub  — public key (share freely)

# Inspect key fingerprint
ssh-keygen -lf ~/.ssh/id_ed25519.pub
```

## Authorizing Keys

```bash
# Copy public key to a remote server
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@host
# Manually: append to ~/.ssh/authorized_keys on the server

# authorized_keys format (one key per line):
# [options] keytype base64key comment
# Examples:
# ssh-ed25519 AAAA... laptop
# from="192.168.1.*" ssh-ed25519 AAAA... restricted-key
# no-pty,command="/usr/bin/rsync" ssh-ed25519 AAAA... deploy-key

# Permissions matter — SSH rejects misconfigured files
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/id_ed25519
```

## ~/.ssh/config — Client Configuration

```
# Global defaults
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_ed25519

# Jump host
Host prod-bastion
    HostName 203.0.113.10
    User ec2-user
    IdentityFile ~/.ssh/prod_key

# Reach internal hosts through bastion
Host prod-*
    User ubuntu
    ProxyJump prod-bastion
    IdentityFile ~/.ssh/prod_key

# Port forward shortcut
Host db-tunnel
    HostName prod-bastion
    User ec2-user
    LocalForward 5432 db.internal:5432
    ExitOnForwardFailure yes
```

```bash
# Use a configured alias
ssh prod-app01        # connects via ProxyJump automatically
```

## SSH Tunnels

```bash
# Local forward: localhost:8080 → remote:80
# Useful: access a remote web server locally
ssh -L 8080:localhost:80 user@host
ssh -L 8080:internal-host:80 user@bastion   # through bastion to internal host

# Remote forward: remote:9090 → localhost:22
# Useful: expose a local service through a remote server
ssh -R 9090:localhost:22 user@host

# Dynamic (SOCKS proxy): all traffic through host
# Useful: route browser traffic through a bastion
ssh -D 1080 user@host
# Then set browser SOCKS5 proxy to localhost:1080

# Flags for tunnels only (no shell):
ssh -N -f user@host -L 5432:db:5432   # -N no command, -f background
```

## SSH Agent

The agent holds decrypted private keys so you don't re-enter passphrases:

```bash
eval $(ssh-agent -s)      # start agent, set SSH_AUTH_SOCK
ssh-add ~/.ssh/id_ed25519 # add key (prompts for passphrase once)
ssh-add -l                # list loaded keys
ssh-add -D                # remove all keys

# Agent forwarding (use sparingly — security risk)
ssh -A user@bastion       # bastion can use your local agent
```

## sshd_config — Server Hardening

Key settings in `/etc/ssh/sshd_config`:

```
Port 2222                         # non-standard port (minor obscurity)
PermitRootLogin no                # never allow direct root SSH
PasswordAuthentication no         # keys only
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
AllowUsers alice bob              # whitelist
AllowGroups sshusers

MaxAuthTries 3                    # limit brute force
LoginGraceTime 30

X11Forwarding no                  # disable unless needed
AllowTcpForwarding yes            # needed for tunnels
GatewayPorts no                   # prevent remote forwards binding 0.0.0.0

# Only modern algorithms
KexAlgorithms curve25519-sha256,diffie-hellman-group16-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-256-etm@openssh.com
```

```bash
# Test config before restarting
sudo sshd -t

# Restart
sudo systemctl restart ssh
```

## Key Concepts

```bash
# known_hosts: trusted host fingerprints
cat ~/.ssh/known_hosts
ssh-keygen -R hostname   # remove stale entry

# Verbose output for debugging
ssh -v user@host         # one level
ssh -vvv user@host       # max verbosity

# Jump through multiple hops
ssh -J user@jump1,user@jump2 user@destination

# Execute a command remotely (no interactive shell)
ssh user@host 'df -h /var'
ssh user@host 'sudo systemctl restart nginx'

# Copy files
scp local.txt user@host:/remote/path/
scp -r user@host:/remote/dir/ local_dir/

# rsync over SSH (preferred for large transfers)
rsync -avz -e ssh ./local/ user@host:/remote/
rsync -avz --delete user@host:/backup/ ./local/
```

## Further Reading

- [OpenSSH Manual Pages](https://www.openssh.com/manual.html) — Index of all OpenSSH man pages: `ssh(1)`, `sshd(8)`, `ssh-keygen(1)`, `ssh-agent(1)`, and `ssh-add(1)`.
- [sshd_config(5)](https://man.openbsd.org/sshd_config) — The authoritative OpenBSD reference for every `sshd_config` directive: `PermitRootLogin`, `AllowUsers`, `KexAlgorithms`, `Ciphers`, and `AuthorizedKeysFile`.
- [ssh_config(5)](https://man.openbsd.org/ssh_config) — Complete client `~/.ssh/config` directive reference including `ProxyJump`, `ControlMaster` multiplexing, `ServerAliveInterval`, and `Match` blocks.
- [RFC 4251 — The Secure Shell (SSH) Protocol Architecture](https://datatracker.ietf.org/doc/html/rfc4251) — The foundational IETF specification for the SSH protocol: transport, authentication, and connection layers.
- [Julia Evans — SSH port forwarding](https://jvns.ca/blog/2022/02/10/an-introduction-to-ssh-port-forwarding/) — Clear diagrams explaining local, remote, and dynamic port forwarding — the three tunnel types covered in this lesson.
