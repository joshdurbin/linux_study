# Exercise: Processes

## Task 1 — Launch and inspect a background process

Start a long-running background process:

```bash
sleep 300 &
```

Then run `ps aux | grep sleep` and save the output to `~/proclab/sleep_ps.txt` (create the directory first). The file should contain the line showing the sleep process.

## Task 2 — Capture ps output

Run `ps aux` and save the full output to `~/proclab/all_processes.txt`. Then count the number of lines (processes) and save just the count to `~/proclab/process_count.txt`.

## Task 3 — Send a signal

Find the PID of your `sleep 300` process using `pgrep sleep`. Send it `SIGTERM` with `kill <PID>`. Then verify it is gone by running `pgrep sleep` again and saving the result (empty or not found) to `~/proclab/after_kill.txt`.

If the process is gone, `pgrep sleep` will exit non-zero and produce no output — that's the expected behavior. Write "terminated" to `~/proclab/after_kill.txt` to confirm you completed the step.

## Task 4 — Job control

Run two background jobs:

```bash
sleep 400 &
sleep 500 &
```

Run `jobs` and redirect the output to `~/proclab/jobs_output.txt`. Then kill both background sleep jobs using `kill %1` and `kill %2` (or `killall sleep`). Verify by running `jobs` again and saving to `~/proclab/jobs_after.txt`.
