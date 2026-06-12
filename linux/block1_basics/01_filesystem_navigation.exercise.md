# Exercise: Filesystem Navigation

Work through these tasks in your terminal. Each one builds on the last.

## Task 1 — Create a practice directory tree

Using `mkdir -p`, create the following nested structure all at once:

```
~/practice/
  notes/
  projects/alpha/
  projects/beta/
```

Then verify it exists with `tree ~/practice` (or `ls -lR ~/practice`).

## Task 2 — Explore with ls flags

Navigate to `/etc` and run three different `ls` commands that show:
1. All files including hidden ones, in long format
2. Files sorted by modification time (newest first)
3. Human-readable file sizes

Save your output to `~/practice/notes/etc_listing.txt` using output redirection.

## Task 3 — Find files

Use `find` to search `/etc` for all files with a `.conf` extension and write the list to `~/practice/notes/conf_files.txt`. Then use `wc -l` to count how many results you found and append that count as the last line of the file.

## Task 4 — Disk usage report

Run `du -sh ~/practice` and save the output to `~/practice/notes/disk_usage.txt`. The file should contain a line that shows the size and path of your practice directory.
