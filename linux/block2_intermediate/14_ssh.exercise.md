# Exercise: SSH Deep Dive

## Tasks

1. **Key generation**: Generate an Ed25519 keypair (no passphrase for this exercise):
   ```bash
   ssh-keygen -t ed25519 -C "linux-study-test" -f ~/practice/test_ed25519 -N ""
   ls -la ~/practice/test_ed25519*
   ssh-keygen -lf ~/practice/test_ed25519.pub > ~/practice/ssh_keygen.txt
   cat ~/practice/test_ed25519.pub >> ~/practice/ssh_keygen.txt
   ```

2. **Write an ~/.ssh/config**: Create `~/practice/ssh_config` with at least 3 Host entries demonstrating:
   - A bastion/jump host entry
   - A ProxyJump-based entry for reaching internal hosts
   - A tunnel entry using LocalForward
   - Global settings (ServerAliveInterval, IdentityFile)

3. **Authorized keys options**: Write `~/practice/authorized_keys_examples.txt` with 3 different `authorized_keys` line formats demonstrating:
   - A plain key
   - A `from=` restricted key
   - A `command=` forced-command key

4. **sshd_config hardening**: Write `~/practice/sshd_hardened.conf` containing at least 6 hardening directives from the lesson (PermitRootLogin, PasswordAuthentication, MaxAuthTries, etc.).

5. **Tunnel reference**: Write `~/practice/ssh_tunnels.txt` with the exact commands for:
   - A local forward of port 5432 (remote PostgreSQL) to local 15432
   - A dynamic SOCKS proxy on port 1080
   - A background non-interactive tunnel (`-N -f`)

## Hints

- `ssh-keygen -f outfile -N ""` generates without prompting for a passphrase
- The `from=` option in authorized_keys restricts which source IPs can use that key
- `command=` in authorized_keys forces a specific command to run instead of a shell — used for deployment keys
