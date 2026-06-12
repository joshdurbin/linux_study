# Exercise: nmap

> Scan only localhost (127.0.0.1) and the local container network in these exercises.

## Tasks

1. **Basic scan**: Run a default TCP scan against localhost and save output:
   ```bash
   nmap -sT localhost -oN ~/practice/nmap_localhost.txt
   cat ~/practice/nmap_localhost.txt
   ```

2. **SYN scan with version detection**: Run a SYN scan (or connect scan) with service detection:
   ```bash
   sudo nmap -sS -sV localhost -oN ~/practice/nmap_version.txt 2>/dev/null || \
   nmap -sT -sV localhost -oN ~/practice/nmap_version.txt
   ```

3. **Specific port range**: Scan the top 100 ports and save in grepable format:
   ```bash
   nmap --top-ports 100 localhost -oG ~/practice/nmap_top100.gnmap
   grep "open" ~/practice/nmap_top100.gnmap || echo "no open ports in top 100"
   ```

4. **NSE default scripts**: Run default scripts against localhost:
   ```bash
   nmap -sC localhost -p 22,80,443 -oN ~/practice/nmap_scripts.txt 2>/dev/null || \
   nmap -sC localhost -oN ~/practice/nmap_scripts.txt
   ```

5. **Write an nmap cheatsheet**: Document in `~/practice/nmap_cheatsheet.txt`:
   - The 5 port states and what each means
   - The command for a comprehensive scan (SYN + version + OS + scripts)
   - The timing template to use on a fast internal network
   - Two output format flags

## Hints

- Without root, nmap falls back from `-sS` to `-sT` automatically
- `--open` flag shows only open ports (cleaner output)
- `nmap localhost` is always safe — you're scanning yourself
- `-oA basename` writes all three output formats at once
