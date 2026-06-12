# Git Advanced

Beyond `add`, `commit`, and `push`, Git offers powerful history manipulation and debugging tools that are essential in real team environments.

## Interactive Rebase

Rebase rewrites commit history. Interactive rebase (`-i`) lets you edit, squash, reorder, or drop commits.

```bash
git rebase -i HEAD~3          # edit last 3 commits
git rebase -i main            # rebase all commits since branching from main
```

In the editor, you'll see each commit with an action prefix:
```
pick abc1234 Add feature
pick def5678 Fix typo
pick ghi9012 Add tests
```

Actions:
| Action | Description |
|--------|-------------|
| `pick` | Keep commit as-is |
| `reword` | Keep commit, edit message |
| `edit` | Stop to amend the commit |
| `squash` | Merge into previous commit (keeps both messages) |
| `fixup` | Merge into previous commit (discards this message) |
| `drop` | Remove commit entirely |

```bash
git rebase --continue   # after resolving conflicts or editing
git rebase --abort      # abandon and return to original state
```

## git stash — Temporary Storage

```bash
git stash                     # stash uncommitted changes (tracked files)
git stash -u                  # also stash untracked files
git stash -p                  # interactive: choose hunks to stash
git stash push -m "WIP: login feature"  # named stash

git stash list                # show all stashes
git stash show stash@{0}      # diff of top stash
git stash pop                 # apply top stash and remove it
git stash apply stash@{1}     # apply without removing
git stash drop stash@{0}      # remove a stash
git stash clear               # remove all stashes
git stash branch new-branch   # create branch from stash
```

## git cherry-pick — Apply Specific Commits

```bash
git cherry-pick abc1234         # apply commit to current branch
git cherry-pick abc..def        # range of commits
git cherry-pick --no-commit abc # apply changes without committing
git cherry-pick --abort         # abort ongoing cherry-pick
git cherry-pick -x abc1234      # add "cherry-picked from" note to message
```

Use case: a bug is fixed on a release branch and you want it on main without merging everything.

## git bisect — Binary Search for Bugs

```bash
git bisect start
git bisect bad                  # current commit is broken
git bisect good v1.2.0          # this tag was known good
# git checks out middle commit; test it
git bisect good                 # if this commit is fine
git bisect bad                  # if this commit is broken
# ... repeat until found ...
git bisect reset                # return to original HEAD

# Automated bisect with a test script
git bisect run ./test.sh        # test.sh exits 0=good, non-zero=bad
```

## git reflog — Recover Lost Commits

The reflog records every HEAD movement — your safety net.

```bash
git reflog                      # all recent HEAD positions
git reflog show main            # movements of main branch
git reflog --date=iso           # with timestamps

# Recover a commit lost by reset
git reflog
git checkout -b recovery abc1234  # create branch at lost commit
git reset --hard abc1234          # or reset HEAD to it
```

## git reset vs git revert

```bash
# reset: moves HEAD (rewrites history — don't use on shared branches)
git reset --soft HEAD~1    # undo last commit, keep changes staged
git reset --mixed HEAD~1   # undo last commit, keep changes unstaged (default)
git reset --hard HEAD~1    # undo last commit and discard changes (destructive!)

# revert: creates a new commit that undoes changes (safe for shared branches)
git revert HEAD            # revert last commit
git revert abc1234         # revert specific commit
git revert HEAD~3..HEAD    # revert multiple commits
git revert --no-commit abc # stage revert without committing
```

**Rule**: Use `reset` on local/private branches. Use `revert` on shared branches.

## git worktree — Multiple Working Trees

```bash
git worktree add ../hotfix hotfix-branch     # check out branch in sibling dir
git worktree add -b new-feature ../feature   # create branch + worktree
git worktree list                            # list all worktrees
git worktree remove ../hotfix               # remove a worktree
```

Worktrees let you work on two branches simultaneously without stashing.

## Practical Patterns

```bash
# Clean up before a PR: squash WIP commits
git rebase -i main

# Bring one fix from another branch
git cherry-pick $(git log --oneline other-branch | grep "fix:" | head -1 | cut -c1-7)

# Find the commit that introduced a bug
git bisect start
git bisect bad HEAD
git bisect good v2.0
git bisect run make test

# Save work quickly before switching tasks
git stash push -m "half-done feature X"
git checkout hotfix-branch
```

## Further Reading

- [Pro Git (free book)](https://git-scm.com/book/en/v2) — the definitive free Git book: chapters on interactive rebase, the reflog, cherry-pick, worktrees, and Git internals (objects, refs, pack files) that explain why these commands work.
- [Git man pages](https://git-scm.com/docs) — authoritative reference for every Git command; the `git-rebase(1)`, `git-bisect(1)`, and `git-reflog(1)` pages document every flag and edge case not covered in the lesson.
- [Atlassian — Advanced Git Tutorials](https://www.atlassian.com/git/tutorials/advanced-overview) — detailed tutorials on rebase vs merge, `git bisect`, `git stash`, hooks, and workflows used in teams — well-illustrated with diagrams of how each operation changes the commit graph.
- [GitHub Git cheat sheet](https://education.github.com/git-cheat-sheet-education.pdf) — GitHub's condensed reference of the most-used commands including all the operations in this lesson: stash, cherry-pick, rebase, bisect, and worktree.
