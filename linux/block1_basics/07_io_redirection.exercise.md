# Exercise: I/O Redirection

## Task 1 — Redirect stdout and stderr

Create the directory `~/iolab/`. Run the following command which produces both stdout (valid path) and stderr (invalid path):

```bash
ls /etc /nonexistent_path_xyz
```

1. Redirect **only stdout** to `~/iolab/stdout.txt`
2. Redirect **only stderr** to `~/iolab/stderr.txt`
3. Redirect **both** to `~/iolab/both.txt` using `2>&1`

## Task 2 — Append and tee

1. Write the line `first line` to `~/iolab/combined.txt` using `>`
2. Append the line `second line` to `~/iolab/combined.txt` using `>>`
3. Run `cat ~/iolab/combined.txt | tee ~/iolab/tee_copy.txt | wc -l > ~/iolab/line_count.txt`

After this, `combined.txt` should have 2 lines, `tee_copy.txt` should be identical to `combined.txt`, and `line_count.txt` should contain `2`.

## Task 3 — Here document

Use a heredoc to write a three-line config to `~/iolab/config.ini`:

```
[server]
host=localhost
port=8080
```

Use `cat << EOF > ~/iolab/config.ini` syntax.

## Task 4 — Discard stderr

Some commands produce noisy error output. Run:

```bash
find / -name "*.conf" 2>/dev/null | head -20 > ~/iolab/conf_search.txt
```

Verify that `conf_search.txt` exists and has content (no stderr noise).
