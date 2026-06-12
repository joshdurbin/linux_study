# Exercise: PATH and Command Resolution

## Setup

```bash
mkdir -p ~/practice/path
```

## Task 1: Classify Commands with type

```bash
# Identify what each of these resolves to
type ls
type cd
type echo
type grep
type history    # builtin!

# Show all matches for a command (not just the first)
type -a echo

# Use type -t for scripting
for cmd in ls cd ll python3 nonexistent_cmd_xyz; do
    result=$(type -t "$cmd" 2>/dev/null)
    echo "$cmd: ${result:-not found}"
done
```

## Task 2: which vs type

```bash
which ls
type ls

# which cannot find builtins
which cd    # no output
type cd     # shows "cd is a shell builtin"

# type -a shows all PATH matches AND aliases/builtins
type -a echo
which -a echo
```

## Task 3: Inspect PATH

```bash
# View PATH as a list (one directory per line)
# grep -o splits on the colon separator by matching everything that is not a colon
echo $PATH | grep -o '[^:]*'

# Count PATH directories
echo $PATH | grep -o '[^:]*' | wc -l

# Check if a specific directory is in PATH
echo $PATH | grep -q "$HOME/.local/bin" && echo "in PATH" || echo "not in PATH"
```

## Task 4: Add to PATH and Observe Resolution

```bash
# Create a personal bin directory and a script in it
mkdir -p ~/practice/path/bin
cat > ~/practice/path/bin/mygreet << 'EOF'
#!/bin/bash
echo "Hello from ~/practice/path/bin/mygreet"
EOF
chmod +x ~/practice/path/bin/mygreet

# Before adding to PATH: command not found
type mygreet 2>/dev/null || echo "mygreet: not found"

# Add to PATH (prepend)
export PATH="$HOME/practice/path/bin:$PATH"

# After: it's found
type mygreet
mygreet
```

## Task 5: PATH Shadowing

```bash
# Create a local 'echo' that shadows the system one
cat > ~/practice/path/bin/echo << 'EOF'
#!/bin/bash
echo "[custom echo]: $*"
EOF
chmod +x ~/practice/path/bin/echo

# Since ~/practice/path/bin is first in PATH, it runs first
echo "test"      # which echo runs?
type echo
type -a echo     # shows all matches in order

# Run the real system echo explicitly
/bin/echo "test"
command echo "test"   # also bypasses aliases/functions

# Cleanup the shadow
rm ~/practice/path/bin/echo
hash -r    # clear the hash cache
```

## Task 6: The Hash Cache

```bash
# See what's cached
hash

# Force a re-lookup for a specific command
hash ls
hash

# Clear the cache entirely
hash -r
hash    # empty
```

## Task 7: command -v for Scripting

```bash
# The POSIX-portable way to check for a command
for tool in ls bash find curl docker kubectl; do
    if command -v "$tool" > /dev/null 2>&1; then
        echo "$tool: found at $(command -v $tool)"
    else
        echo "$tool: NOT FOUND"
    fi
done
```

## Task 8: Write a Script Using PATH Techniques

```bash
cat > ~/practice/path/check_tools.sh << 'EOF'
#!/bin/bash
# Check for required tools and report their paths
REQUIRED="ls grep find awk"
MISSING=0

for tool in $REQUIRED; do
    if command -v "$tool" > /dev/null 2>&1; then
        echo "OK: $tool -> $(command -v $tool)"
    else
        echo "MISSING: $tool"
        MISSING=$((MISSING + 1))
    fi
done

echo ""
echo "PATH has $(echo $PATH | grep -o '[^:]*' | wc -l) directories"
[ $MISSING -eq 0 ] && echo "All required tools found." || echo "$MISSING tool(s) missing."
EOF
chmod +x ~/practice/path/check_tools.sh
bash ~/practice/path/check_tools.sh
```

## Expected Outcome

- `type` classifies commands as file, builtin, alias, or function
- `which` finds binaries in PATH but not builtins or aliases
- `command -v` is the portable way to test for a binary in scripts
- `hash -r` clears the shell's command location cache
- `~/practice/path/bin/mygreet` is runnable after prepending its directory to PATH
- `~/practice/path/check_tools.sh` uses `command -v` to check for required tools
