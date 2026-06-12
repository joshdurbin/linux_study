# Exercise: Permissions

## Task 1 — Create files with specific permissions

Create the directory `~/permlab/`. Inside it, create the following files and set their permissions exactly:

1. `secret.txt` — write anything to it, then set permissions to `600` (owner read/write only)
2. `script.sh` — write `#!/bin/bash\necho hello` to it, then set permissions to `755`
3. `shared.txt` — write anything to it, then set permissions to `644`

## Task 2 — Verify permissions with ls

Run `ls -la ~/permlab/` and redirect the output to `~/permlab/permissions_listing.txt`.

## Task 3 — Use symbolic chmod

Starting from `shared.txt` (currently `644`), use symbolic mode chmod to:
1. Remove read permission from others: `chmod o-r ~/permlab/shared.txt`
2. Add execute permission for the owner: `chmod u+x ~/permlab/shared.txt`

After both changes, the permission should be `740` (`rwxr-----`). Verify with `ls -la`.

## Task 4 — Check umask

Run `umask` and save the output to `~/permlab/umask_value.txt`. Then create a new file `~/permlab/umask_test.txt` using `touch` and run `stat -c "%a %n" ~/permlab/umask_test.txt` to save the octal permissions to `~/permlab/umask_result.txt`.
