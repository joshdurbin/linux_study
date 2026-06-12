# Exercise: pprof, Heap Dumps, and Memory Profiling

## Tasks

1. **smaps analysis**: Run the following to analyze your current shell's memory layout:
   ```bash
   grep -E "^(Size|Rss|Pss|Private_Dirty)" /proc/$$/smaps | \
     awk '/^Size/{size=$2} /^Rss/{rss=$2} /^Private_Dirty/{print size, rss, $2}' | \
     sort -rn | head -10 > ~/practice/smaps_top.txt
   ```
   Also capture total private dirty: `grep Private_Dirty /proc/$$/smaps | awk '{s+=$2} END{print s/1024 "MB total private dirty"}' >> ~/practice/smaps_top.txt`

2. **Process memory tracking**: Pick any running process (find one with `ps aux | grep -v grep | tail -5`) and record its memory stats:
   ```bash
   PID=$(ps aux | grep -v grep | awk 'NR==3{print $2}')
   grep -E "^(VmRSS|VmSize|VmPeak|VmSwap)" /proc/$PID/status > ~/practice/process_memory.txt
   echo "PID: $PID" >> ~/practice/process_memory.txt
   ```

3. **gcore knowledge**: Write `~/practice/gcore_notes.txt` explaining what `gcore` does, what ptrace is used for, and the command to take a core dump of PID 1234 without killing it.

4. **pprof profile types**: Write `~/practice/pprof_profiles.txt` listing the 6 profile endpoints from `net/http/pprof` with a one-line description of each (`heap`, `profile`, `goroutine`, `allocs`, `block`, `mutex`).

5. **Page fault analysis**: Run `perf stat -e major-faults,minor-faults ls /etc 2>&1 || sudo perf stat -e major-faults,minor-faults ls /etc 2>&1 || echo "perf not available" > ~/practice/page_faults.txt` and save to `~/practice/page_faults.txt`.

## Hints

- `/proc/PID/smaps` requires the process to be running and readable by your user
- `gcore` needs `ptrace_scope` to be permissive — in containers it may require `--cap-add=SYS_PTRACE`
- pprof HTTP endpoint requires the Go app to import `_ "net/http/pprof"` — document the pattern even without a running app
