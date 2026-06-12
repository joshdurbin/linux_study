# Exercise: nsenter and Namespace Tools

## Tasks

1. **Inspect own namespaces**: Run `ls -la /proc/$$/ns/` and save the output to `~/practice/my_namespaces.txt`. Note the inode number for each namespace type.

2. **List all system namespaces**: Run `lsns` and save to `~/practice/lsns_output.txt`. How many distinct network namespaces exist?

3. **Compare namespaces**: Compare PID 1's namespaces to your current shell's:
   ```bash
   diff <(ls -la /proc/1/ns/ 2>/dev/null) <(ls -la /proc/$$/ns/) > ~/practice/ns_diff.txt || true
   cat ~/practice/ns_diff.txt
   ```

4. **Create an isolated network namespace** with `unshare`:
   ```bash
   # This creates a new net namespace where only loopback exists
   sudo unshare --net bash -c "ip addr show > ~/practice/unshare_net.txt && echo 'isolated network namespace' >> ~/practice/unshare_net.txt"
   ```
   Verify `~/practice/unshare_net.txt` only shows the `lo` interface.

5. **nsenter into PID 1**: Enter PID 1's UTS namespace and read the hostname:
   ```bash
   sudo nsenter --target 1 --uts -- hostname > ~/practice/nsenter_hostname.txt 2>&1 || \
     echo "nsenter requires privileged container" > ~/practice/nsenter_hostname.txt
   ```

## Hints

- `lsns` needs root to see all namespaces: `sudo lsns`
- `unshare --net` changes the network namespace — commands inside see no network
- In an unprivileged container, `nsenter` into PID 1 may fail — the file should contain the error message
