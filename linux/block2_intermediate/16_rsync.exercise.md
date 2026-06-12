# Exercise: rsync

## Tasks

1. **Local sync with dry run**: Create source data and sync it locally:
   ```bash
   mkdir -p ~/practice/rsync_src ~/practice/rsync_dst
   echo "file1 content" > ~/practice/rsync_src/file1.txt
   echo "file2 content" > ~/practice/rsync_src/file2.txt
   mkdir ~/practice/rsync_src/subdir
   echo "nested" > ~/practice/rsync_src/subdir/nested.txt

   # Dry run first
   rsync -avn ~/practice/rsync_src/ ~/practice/rsync_dst/ > ~/practice/rsync_dryrun.txt
   cat ~/practice/rsync_dryrun.txt
   ```

2. **Perform the sync**: Run the actual sync and verify:
   ```bash
   rsync -av ~/practice/rsync_src/ ~/practice/rsync_dst/ > ~/practice/rsync_result.txt
   diff -r ~/practice/rsync_src/ ~/practice/rsync_dst/ && echo "IDENTICAL" >> ~/practice/rsync_result.txt
   ```

3. **Incremental sync**: Modify a file and re-sync — verify only the changed file transfers:
   ```bash
   echo "updated content" >> ~/practice/rsync_src/file1.txt
   rsync -av --stats ~/practice/rsync_src/ ~/practice/rsync_dst/ > ~/practice/rsync_incremental.txt
   grep -E "(Number of.*transferred|file1)" ~/practice/rsync_incremental.txt
   ```

4. **Delete mode**: Remove a file from source and sync with `--delete`:
   ```bash
   rm ~/practice/rsync_src/file2.txt
   rsync -av --delete ~/practice/rsync_src/ ~/practice/rsync_dst/ > ~/practice/rsync_delete.txt
   ls ~/practice/rsync_dst/ >> ~/practice/rsync_delete.txt
   ```

5. **Exclude patterns**: Sync with exclusions:
   ```bash
   echo "secret" > ~/practice/rsync_src/.env
   echo "log data" > ~/practice/rsync_src/app.log
   mkdir -p ~/practice/rsync_excl_dst
   rsync -av --exclude='.env' --exclude='*.log' \
     ~/practice/rsync_src/ ~/practice/rsync_excl_dst/ > ~/practice/rsync_exclude.txt
   ls ~/practice/rsync_excl_dst/ >> ~/practice/rsync_exclude.txt
   ```

## Hints

- The trailing slash on source is critical: `rsync src/ dst/` syncs contents; `rsync src dst/` syncs the directory
- `--dry-run` (`-n`) is your safety net — always use it before `--delete`
- `--stats` shows "Number of regular files transferred" — useful to verify only deltas transferred
