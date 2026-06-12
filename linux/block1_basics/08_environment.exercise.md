# Exercise: Environment Variables

## Task 1 — Inspect the environment

Create the directory `~/envlab/`. Run `env` and save the output to `~/envlab/env_snapshot.txt`. Then run `echo $PATH` and save the output to `~/envlab/path_value.txt`.

## Task 2 — Set and use variables

In your current shell, set an environment variable and use it:

```bash
export GREETING="hello from linux"
echo $GREETING > ~/envlab/greeting.txt
```

Also save the value of `$HOME` to `~/envlab/home_value.txt` and `$USER` to `~/envlab/user_value.txt`.

## Task 3 — Exit code checking

Run each of the following commands, capture `$?` immediately after each, and save the results to `~/envlab/exit_codes.txt`. The file should have one line per result in the format `command: N`:

1. `ls /etc` (should be 0)
2. `ls /this_does_not_exist_xyz` (should be non-zero)
3. `true` (always 0)
4. `false` (always 1)

## Task 4 — Modify PATH and test

Add `/usr/local/sbin` to the beginning of your PATH in the current shell:

```bash
export PATH="/usr/local/sbin:$PATH"
```

Save the new value of `$PATH` to `~/envlab/new_path.txt`. Verify the file starts with `/usr/local/sbin`.
