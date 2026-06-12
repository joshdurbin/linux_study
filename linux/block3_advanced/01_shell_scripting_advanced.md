# Advanced Shell Scripting

Beyond basic conditionals and loops, production shell scripts use strict error handling, option parsing, signal trapping, and parallel execution.

## set — Shell Options

```bash
set -e            # exit immediately if any command fails
set -u            # treat unset variables as errors
set -o pipefail   # pipeline fails if any command fails (not just last)
set -x            # print each command before executing (debug mode)
set -n            # dry run: parse but do not execute

# Combine at the top of every script:
set -euo pipefail
```

Why `-o pipefail` matters:
```bash
# Without pipefail: this exits 0 even though grep failed!
cat missing_file.txt | grep "pattern"  # cat fails, but pipeline returns grep's exit code

# With pipefail: exits non-zero if cat fails
set -o pipefail
cat missing_file.txt | grep "pattern"  # now exits non-zero
```

## getopts — Option Parsing

```bash
#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [-v] [-o output] [-n count] input_file"
  exit 1
}

VERBOSE=false
OUTPUT=""
COUNT=10

while getopts "vo:n:h" opt; do
  case "$opt" in
    v) VERBOSE=true ;;
    o) OUTPUT="$OPTARG" ;;
    n) COUNT="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))  # remove processed options from $@

# Now $1 is the first non-option argument
INPUT="${1:-}"
[[ -z "$INPUT" ]] && usage
```

## trap — Signal Handling and Cleanup

```bash
# Clean up temp files on exit
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

# Handle Ctrl-C gracefully
trap 'echo "Interrupted. Cleaning up..."; exit 130' INT TERM

# Multiple signals
trap cleanup EXIT INT TERM
cleanup() {
  echo "Cleaning up..."
  rm -rf "$WORK_DIR"
}

# Debug: trace every line
trap 'echo "Line $LINENO: $BASH_COMMAND"' DEBUG

# Disable a trap
trap - EXIT
```

## Heredocs

```bash
# Feed a block of text to a command
cat << 'EOF'
This is literal text — no variable expansion.
$HOME won't be expanded.
EOF

# With expansion (no quotes on EOF)
cat << EOF
Home is $HOME
User is $USER
EOF

# Indented heredoc (bash 4.4+, removes leading tabs)
cat <<- EOF
	This text is indented with a tab
	The tab is stripped from output
	EOF

# To a file
cat > /etc/myapp.conf << EOF
[settings]
port=8080
host=$HOSTNAME
EOF
```

## Process Substitution

```bash
# Use command output as a file
diff <(ls dir1/) <(ls dir2/)
wc -l <(find . -name "*.go")
sort -m <(sort file1) <(sort file2)

# Read from command while preserving shell vars
while IFS= read -r line; do
  process "$line"
done < <(find . -name "*.conf")
# Note: < <(cmd) not <(cmd) — the < feeds the process substitution as stdin
```

## xargs -P — Parallel Execution

```bash
# Run up to 4 parallel jobs
find . -name "*.jpg" | xargs -P 4 -I {} convert {} {}.png

# With null-delimited input (safe for filenames with spaces)
find . -name "*.txt" -print0 | xargs -0 -P 8 grep -l "pattern"

# Control arguments per invocation with -n
echo "a b c d" | xargs -n 1 echo   # one arg per call
cat list.txt | xargs -P 4 -n 1 process_item
```

## Advanced Variable Tricks

```bash
# Default value if unset or empty
DB_HOST="${DB_HOST:-localhost}"

# Fail if required var is missing
API_KEY="${API_KEY:?API_KEY must be set}"

# Array handling
FILES=("a.txt" "b.txt" "c.txt")
for f in "${FILES[@]}"; do echo "$f"; done
echo "Count: ${#FILES[@]}"

# Name reference (bash 4.4+)
declare -n ref=myvar
myvar="hello"
echo "$ref"    # prints "hello"

# Associative arrays
declare -A MAP
MAP["key1"]="value1"
MAP["key2"]="value2"
echo "${MAP["key1"]}"
for k in "${!MAP[@]}"; do echo "$k: ${MAP[$k]}"; done
```

## Robust Script Template

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${TMPDIR:-/tmp}/$(basename "$0").log"

log() { echo "[$(date +%T)] $*" | tee -a "$LOG_FILE"; }
die() { echo "ERROR: $*" >&2; exit 1; }

trap 'log "Script exited with status $?"' EXIT

main() {
  log "Starting..."
  # logic here
  log "Done."
}

main "$@"
```

## Further Reading

- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/) — comprehensive reference covering every Bash feature in this lesson: `set` options, `getopts`, `trap`, heredocs, process substitution, and arrays with hundreds of annotated examples.
- [BashFAQ/035 — How to parse options](https://mywiki.wooledge.org/BashFAQ/035) — Greg Wooledge's authoritative answer on `getopts` vs `getopt` vs manual parsing, with edge cases and portability notes.
- [Bash Manual — The Set Builtin](https://www.gnu.org/software/bash/manual/bash.html#The-Set-Builtin) — official GNU documentation for every `set -` flag: `-e`, `-u`, `-o pipefail`, `-x`, and `-n`, with exact semantics.
- [BashPitfalls](https://mywiki.wooledge.org/BashPitfalls) — annotated catalogue of common Bash mistakes, including why `set -e` alone is not enough and how process substitution interacts with `set -o pipefail`.
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) — Google's production shell scripting standards covering error handling, quoting, function design, and when to use Python instead of Bash.
