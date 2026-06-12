# Exercise: Users and Groups

## Task 1 — Inspect your identity

Create the directory `~/userlab/`. Run the following commands and save their output to files:

1. `whoami` → `~/userlab/whoami.txt`
2. `id` → `~/userlab/id_output.txt`
3. `groups` → `~/userlab/groups.txt`

## Task 2 — Explore /etc/passwd

Run the following and save to `~/userlab/`:

1. Count the total number of lines in `/etc/passwd` → save the number to `user_count.txt`
2. Extract just the usernames (field 1, colon-delimited) and sort them → save to `usernames.txt`
3. Find all users with `/bin/bash` as their shell (look in field 7) → save to `bash_users.txt`

```bash
# Hint for field extraction:
cut -d: -f1 /etc/passwd | sort
grep '/bin/bash$' /etc/passwd | cut -d: -f1
```

## Task 3 — Inspect /etc/group

Run `cat /etc/group` and save to `~/userlab/groups_db.txt`. Then find all groups that your current username belongs to by grepping for your username in `/etc/group` and save to `~/userlab/my_groups.txt`.

## Task 4 — Check sudo membership

Check whether your current user is in the `sudo` group. Save the result as either the word `yes` or `no` to `~/userlab/has_sudo.txt`. 

```bash
groups | grep -q sudo && echo "yes" || echo "no"
```
