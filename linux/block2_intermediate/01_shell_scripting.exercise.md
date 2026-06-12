# Exercise: Shell Scripting

## Task 1 — Write a basic script

Create `~/scripts/greet.sh` that:
1. Takes one argument (a name)
2. Prints `Hello, <name>!` if an argument is provided
3. Prints `Usage: greet.sh <name>` and exits with code 1 if no argument is given

Make it executable with `chmod +x ~/scripts/greet.sh`. Test it:

```bash
~/scripts/greet.sh Alice   # should print: Hello, Alice!
~/scripts/greet.sh         # should print usage and exit 1
```

## Task 2 — Write a loop script

Create `~/scripts/counter.sh` that:
1. Takes one numeric argument N
2. Prints the numbers 1 through N, one per line
3. After the loop, prints `Done. Counted to N.`

Run `~/scripts/counter.sh 5` and save the output to `~/scripts/counter_output.txt`.

## Task 3 — Write a file-processing script

Create `~/scripts/find_large.sh` that:
1. Takes a directory path as `$1` and a size (in MB) as `$2`
2. Uses `find` to list all files larger than that size in bytes
3. Prints each filename found
4. If no arguments given, prints usage

Run it: `~/scripts/find_large.sh /usr 10` and save output to `~/scripts/large_files.txt`.

## Task 4 — Exit codes

Create `~/scripts/check_file.sh` that:
1. Takes a filename as `$1`
2. Exits 0 with message `EXISTS: <file>` if the file exists
3. Exits 1 with message `MISSING: <file>` if not

Test: `~/scripts/check_file.sh /etc/passwd` should print `EXISTS: /etc/passwd` and exit 0.
Save that output to `~/scripts/check_output.txt`.
