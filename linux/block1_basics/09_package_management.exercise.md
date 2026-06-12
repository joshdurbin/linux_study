# Exercise: Package Management

## Task 1 — Check installed packages

Run `dpkg -l` and save the full output to `~/pkglab/installed_packages.txt` (create the directory first). Then count the number of installed packages (lines starting with `ii`) and save just that number to `~/pkglab/install_count.txt`.

```bash
dpkg -l | grep "^ii" | wc -l
```

## Task 2 — Search and inspect a package

Use `apt show curl` to display information about the `curl` package and save it to `~/pkglab/curl_info.txt`. The file should contain the package's Version, Description, and Depends fields.

## Task 3 — Locate commands

Run the following commands and save all output to `~/pkglab/command_locations.txt`:
1. `which bash`
2. `which python3` (may not exist — use `which python3 2>/dev/null || echo "python3 not found"`)
3. `whereis ls`
4. `type -a ls`

## Task 4 — List files from a package

Run `dpkg -L bash` to list all files installed by the `bash` package and save to `~/pkglab/bash_files.txt`. Then use `grep` to extract only the lines containing `/bin/` and save to `~/pkglab/bash_bins.txt`.
