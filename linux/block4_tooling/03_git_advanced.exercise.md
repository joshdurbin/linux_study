# Exercise: Git Advanced

## Setup — Create a practice repo

```bash
mkdir -p ~/gitlab && cd ~/gitlab
git init
git config user.email "student@lab.local"
git config user.name "Student"

# Create initial commits
echo "initial" > file.txt && git add file.txt && git commit -m "initial commit"
echo "feature A" >> file.txt && git add file.txt && git commit -m "add feature A"
echo "wip changes" >> file.txt && git add file.txt && git commit -m "WIP: unfinished"
echo "feature B" >> file.txt && git add file.txt && git commit -m "add feature B"
```

## Task 1 — git stash

1. Make an uncommitted change: `echo "experimental" >> ~/gitlab/file.txt`
2. Stash it with a message: `git stash push -m "experimental change"`
3. Save `git stash list` output to `~/gitlab/stash_list.txt`
4. Re-apply the stash: `git stash pop`
5. Save `git diff HEAD` to `~/gitlab/stash_applied.txt`

## Task 2 — Interactive rebase (squash)

Squash the last 3 commits (the WIP and feature commits) into a single commit with message "add features A and B":

```bash
cd ~/gitlab
git rebase -i HEAD~3
# In the editor: change second and third 'pick' to 'squash' (or 'fixup')
# Edit the commit message to "add features A and B"
```

After the rebase, run `git log --oneline -5` and save to `~/gitlab/log_after_rebase.txt`. The WIP commit should be gone.

## Task 3 — git cherry-pick

Create a new branch and add a commit, then cherry-pick it to main:

```bash
cd ~/gitlab
git checkout -b hotfix
echo "critical fix" >> ~/gitlab/file.txt
git add file.txt
git commit -m "fix: critical bug"
git checkout main  # or 'master'

# Cherry-pick the hotfix commit
git cherry-pick hotfix
```

Save `git log --oneline -5` to `~/gitlab/log_after_cherry_pick.txt`. It should show the "fix: critical bug" commit on main.

## Task 4 — git reflog

Run `git reflog` and save to `~/gitlab/reflog_output.txt`. The file should show the history of HEAD movements including the rebase and cherry-pick operations.
