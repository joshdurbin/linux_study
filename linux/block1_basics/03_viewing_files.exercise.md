# Exercise: Viewing Files

## Task 1 — Create a sample file

Create a file `~/viewtest/sample.txt` with at least 30 lines of content. You can generate it with:

```bash
mkdir -p ~/viewtest
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do echo "Line $i: the quick brown fox"; done > ~/viewtest/sample.txt
```

Then use `head -5` and `tail -5` to verify the first and last 5 lines.

## Task 2 — Count and redirect

Use `wc` to count the number of lines, words, and bytes in `~/viewtest/sample.txt`. Redirect the full `wc` output (all three counts) to `~/viewtest/wc_output.txt`.

## Task 3 — Identify file types

Run the `file` command on each of the following and redirect all output to `~/viewtest/file_types.txt`:
- `~/viewtest/sample.txt`
- `/bin/ls`
- `/etc/passwd`

The output file should have three lines, one for each file identified.

## Task 4 — Hexdump inspection

Run `hexdump -C /etc/hostname` and save the first 4 lines of output to `~/viewtest/hex_output.txt` (use `head -4`).
