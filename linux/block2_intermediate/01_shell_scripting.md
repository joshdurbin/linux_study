# Shell Scripting

Shell scripts automate repetitive tasks, orchestrate commands, and encode operational knowledge. A good shell script is readable, handles errors, and behaves predictably.

## The Shebang

```bash
#!/bin/bash          # use bash
#!/usr/bin/env bash  # find bash via PATH (more portable)
#!/bin/sh            # POSIX sh (more portable, fewer features)
```

Always include a shebang. Make the script executable: `chmod +x script.sh`.

## Variables

```bash
NAME="world"
echo "Hello, $NAME"
echo "Hello, ${NAME}!"   # braces needed adjacent to text

# Command substitution
TODAY=$(date +%Y-%m-%d)
FILES=$(ls ~/Documents | wc -l)

# Arithmetic
X=5
Y=$((X * 2 + 1))
echo $Y    # 11
((X++))    # increment in place
```

## Positional Parameters

```bash
# Called as: ./script.sh arg1 arg2 arg3
$0    # script name
$1    # first argument
$2    # second argument
$@    # all arguments as separate words (use this in loops)
$*    # all arguments as one string
$#    # number of arguments

# Example
echo "Script: $0"
echo "First arg: $1"
echo "All args: $@"
echo "Arg count: $#"
```

## if / elif / else

```bash
if [[ condition ]]; then
  # ...
elif [[ other ]]; then
  # ...
else
  # ...
fi
```

Common test operators:
```bash
[[ -f file ]]        # file exists and is regular
[[ -d dir ]]         # directory exists
[[ -z "$var" ]]      # string is empty
[[ -n "$var" ]]      # string is non-empty
[[ "$a" == "$b" ]]   # string equality
[[ "$a" != "$b" ]]   # string inequality
[[ $n -eq 5 ]]       # numeric equal
[[ $n -lt 10 ]]      # numeric less than
[[ $n -ge 0 ]]       # numeric greater-or-equal
```

## Loops

```bash
# for loop over a list
for item in one two three; do
  echo "$item"
done

# for loop over files
for f in *.txt; do
  echo "Processing $f"
done

# C-style for loop
for ((i=0; i<5; i++)); do
  echo "$i"
done

# while loop
count=0
while [[ $count -lt 5 ]]; do
  echo "count: $count"
  ((count++))
done

# read lines from a file
while IFS= read -r line; do
  echo "$line"
done < input.txt
```

## Functions

```bash
greet() {
  local name="$1"    # local prevents polluting global scope
  echo "Hello, $name!"
}

greet "Alice"
greet "Bob"

# Functions can return exit codes (not values)
is_even() {
  [[ $(($1 % 2)) -eq 0 ]]
}

if is_even 4; then echo "even"; fi
```

## Exit Codes

```bash
exit 0    # success
exit 1    # general error
exit 2    # misuse of command

# Check if last command succeeded
if ! cp src dst; then
  echo "Copy failed" >&2
  exit 1
fi

# Short-circuit
cp src dst || { echo "Copy failed"; exit 1; }
cp src dst && echo "Copy succeeded"
```

## Error Output

Always send error messages to stderr:

```bash
echo "ERROR: file not found" >&2
```

## Practical Script Template

```bash
#!/usr/bin/env bash
set -euo pipefail    # exit on error, undefined vars, pipe failure

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
  echo "Usage: $0 <input_file> <output_dir>"
  exit 1
}

[[ $# -ne 2 ]] && usage

INPUT="$1"
OUTPUT_DIR="$2"

[[ -f "$INPUT" ]] || { echo "ERROR: $INPUT not found" >&2; exit 1; }
mkdir -p "$OUTPUT_DIR"

echo "Processing $INPUT..."
# ... rest of script
```

## Further Reading

- [GNU Bash Manual](https://www.gnu.org/software/bash/manual/bash.html) — The authoritative reference for every bash feature: arrays, parameter expansion, `[[ ]]` conditionals, arithmetic, and process substitution.
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/) — Comprehensive community guide covering advanced topics: arrays, regular expressions in scripts, here-documents, and debugging techniques.
- [Greg's Bash Guide](https://mywiki.wooledge.org/BashGuide) — Well-regarded practical guide focused on writing correct, safe bash; covers quoting, word splitting, and globbing pitfalls that trip up beginners.
- [BashFAQ](https://mywiki.wooledge.org/BashFAQ) — Indexed answers to common bash scripting questions including `read` loops, arrays, `set -e` gotchas, and portability.
- [Julia Evans — Bash quirks](https://jvns.ca/blog/2017/03/26/bash-quirks/) — Short, focused post on the surprising parts of bash: `set -e` exceptions, `IFS`, and why quoting matters.
