# Exercise: Text Search

## Task 1 — Set up search data

Create the directory `~/searchlab/` and inside it create a file `logs.txt` with the following content (copy exactly):

```
2024-01-10 ERROR: disk full on /dev/sda1
2024-01-10 INFO: service started
2024-01-11 WARNING: high memory usage
2024-01-11 ERROR: connection refused to 192.168.1.5
2024-01-12 INFO: backup completed
2024-01-12 error: timeout after 30s
```

## Task 2 — grep searches

Run the following searches and save results to files in `~/searchlab/`:

1. Case-insensitive search for "error" in `logs.txt` → save to `errors.txt`
2. Recursive, case-insensitive search for "root" in `/etc` (files only, suppress permission errors with `2>/dev/null`) → save matching **filenames only** (use `-l`) to `root_files.txt`

## Task 3 — find exercises

1. Use `find` to locate all `.conf` files in `/etc` that are **regular files** (not directories or symlinks). Save the list to `~/searchlab/conf_list.txt`.
2. Use `find` to locate all files in `/etc` modified in the last 1 day. Save the list to `~/searchlab/recent_files.txt`.

## Task 4 — Count and combine

Use `grep -c` to count how many lines in `logs.txt` contain "INFO" and save just the count number to `~/searchlab/info_count.txt`. The file should contain only a number.
