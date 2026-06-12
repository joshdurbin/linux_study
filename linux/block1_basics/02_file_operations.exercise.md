# Exercise: File Operations

## Task 1 — Build a directory structure and files

Create the directory `~/fileops/` with subdirectories `originals/` and `backups/`. Inside `originals/`, create three files: `alpha.txt`, `beta.txt`, and `gamma.txt`. Put the text `hello from alpha` in `alpha.txt`, `hello from beta` in `beta.txt`, and `hello from gamma` in `gamma.txt`.

## Task 2 — Copy and move

1. Copy all three files from `~/fileops/originals/` into `~/fileops/backups/` in a single command.
2. Rename `~/fileops/originals/gamma.txt` to `~/fileops/originals/gamma_renamed.txt`.

## Task 3 — Create links

1. Create a symbolic link at `~/fileops/alpha_link.txt` that points to `~/fileops/originals/alpha.txt`.
2. Create a hard link at `~/fileops/originals/alpha_hard.txt` that points to the same file as `~/fileops/originals/alpha.txt`.

Verify both links exist (`ls -la ~/fileops/` and `ls -i ~/fileops/originals/`).

## Task 4 — stat a file

Run `stat ~/fileops/originals/alpha.txt` and redirect the output to `~/fileops/stat_output.txt`.
