# Exercise: Advanced Shell Scripting

## Task 1 — Strict mode script with getopts

Create `~/advscripts/process.sh` that:
1. Uses `set -euo pipefail` at the top
2. Accepts options: `-v` (verbose), `-o <outfile>` (output file), `-h` (help/usage)
3. Accepts one positional argument: a directory path
4. Lists `.txt` files in the directory (use `find`)
5. If `-v` is set, prints "Verbose mode enabled" before the list
6. Writes output to the outfile if `-o` is given, else prints to stdout

Make it executable and test:
```bash
mkdir -p ~/advscripts ~/advscripts/data
touch ~/advscripts/data/a.txt ~/advscripts/data/b.txt ~/advscripts/data/c.log
chmod +x ~/advscripts/process.sh
~/advscripts/process.sh -v -o ~/advscripts/output.txt ~/advscripts/data
```

## Task 2 — trap for cleanup

Create `~/advscripts/cleanup_demo.sh` that:
1. Creates a temp file with `mktemp` and stores path in a variable
2. Writes "temp data" to the temp file
3. Registers a `trap` to delete the temp file on EXIT
4. Writes the temp file path to `~/advscripts/tempfile_path.txt`
5. Exits normally

After the script runs, verify the temp file is gone but `tempfile_path.txt` contains the path that was used.

## Task 3 — xargs parallel

Create a directory `~/advscripts/images/` with 6 fake "image" files:
```bash
for i in {1..6}; do echo "fake image $i" > ~/advscripts/images/img$i.raw; done
```

Write `~/advscripts/parallel_process.sh` that uses `find` + `xargs -P 3` to run `wc -c` (byte count) on each `.raw` file in parallel and saves all output to `~/advscripts/parallel_output.txt`.

## Task 4 — Heredoc to file

Write a script `~/advscripts/gen_config.sh` that uses a heredoc (with variable expansion) to generate `~/advscripts/generated.conf` containing:
```
hostname=<actual $HOSTNAME value>
user=<actual $USER value>
date=<output of date +%Y-%m-%d>
```

Run it and verify `~/advscripts/generated.conf` has all three lines.
