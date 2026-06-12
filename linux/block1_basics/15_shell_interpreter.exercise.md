# Exercise: Shell Interpreters

## Setup

```bash
mkdir -p ~/practice/interpreter
```

## Task 1: Identify Your Current Interpreter

```bash
# Login shell
echo "Login shell: $SHELL"

# Current running interpreter
echo "Current interpreter: $0"

# Full path of the running interpreter
readlink /proc/$$/exe

# Is this an interactive or non-interactive shell?
[[ $- == *i* ]] && echo "interactive" || echo "non-interactive"
```

## Task 2: Write Scripts with Different Shebangs

Write a bash script and a POSIX sh script:

```bash
# Bash script — uses bash-specific syntax
cat > ~/practice/interpreter/bash_script.sh << 'EOF'
#!/bin/bash
# bash-specific: arrays and [[ ]]
fruits=("apple" "banana" "cherry")
for fruit in "${fruits[@]}"; do
    if [[ "$fruit" == "banana" ]]; then
        echo "Found banana!"
    fi
done
echo "Shell: $0"
EOF
chmod +x ~/practice/interpreter/bash_script.sh
bash ~/practice/interpreter/bash_script.sh
```

```bash
# POSIX sh script — no bash-specific features
cat > ~/practice/interpreter/sh_script.sh << 'EOF'
#!/bin/sh
# POSIX-compatible: no arrays, no [[ ]]
found=0
for fruit in apple banana cherry; do
    if [ "$fruit" = "banana" ]; then
        found=1
        echo "Found banana!"
    fi
done
echo "Shell: $0"
EOF
chmod +x ~/practice/interpreter/sh_script.sh
sh ~/practice/interpreter/sh_script.sh
```

## Task 3: #!/usr/bin/env bash vs #!/bin/bash

```bash
# Where is bash on this system?
which bash
readlink -f $(which bash)

# The env shebang finds bash via PATH
cat > ~/practice/interpreter/env_bash.sh << 'EOF'
#!/usr/bin/env bash
echo "Running with: $(readlink /proc/$$/exe)"
echo "Bash version: $BASH_VERSION"
EOF
chmod +x ~/practice/interpreter/env_bash.sh
~/practice/interpreter/env_bash.sh
```

## Task 4: See That /bin/sh is dash on Ubuntu

```bash
ls -la /bin/sh
readlink /bin/sh    # should show "dash" on Ubuntu/Debian

# bash and dash behave differently
echo "Testing [[ ]] in bash:"
bash -c '[[ "a" == "a" ]] && echo "bash: [[ ]] works"'

echo "Testing [[ ]] in sh (dash):"
sh -c '[[ "a" == "a" ]] && echo "sh: works" || echo "sh: [[ ]] NOT supported"'
```

## Task 5: View and Understand /etc/shells

```bash
cat /etc/shells
echo ""
echo "Your login shell ($SHELL) is listed: $(grep -q "^$SHELL$" /etc/shells && echo yes || echo no)"
```

## Task 6: Detect Shell Type Inside a Script

```bash
cat > ~/practice/interpreter/detect_shell.sh << 'EOF'
#!/bin/bash
echo "Script name (\$0): $0"
echo "Interpreter: $(readlink /proc/$$/exe)"

if [[ $- == *i* ]]; then
    echo "Mode: interactive"
else
    echo "Mode: non-interactive (script)"
fi

if shopt -q login_shell 2>/dev/null; then
    echo "Type: login shell"
else
    echo "Type: non-login shell"
fi
EOF
chmod +x ~/practice/interpreter/detect_shell.sh

# Run as a normal script (non-interactive, non-login)
bash ~/practice/interpreter/detect_shell.sh
```

## Task 7: Shebang vs Explicit Interpreter

```bash
# Create a script with a bash shebang but sh-incompatible code
cat > ~/practice/interpreter/shebang_test.sh << 'EOF'
#!/bin/bash
arr=(one two three)
echo "Array element: ${arr[1]}"
EOF
chmod +x ~/practice/interpreter/shebang_test.sh

# Using the shebang (kernel runs bash)
~/practice/interpreter/shebang_test.sh

# Using sh directly (shebang is ignored — sh sees bash syntax)
sh ~/practice/interpreter/shebang_test.sh 2>&1 | head -3
echo "sh exit code: $?"
```

## Expected Outcome

- `readlink /proc/$$/exe` shows the full path of the running interpreter
- `bash_script.sh` runs successfully with bash arrays and `[[ ]]`
- `sh_script.sh` runs successfully with POSIX-only syntax
- `/bin/sh` is a symlink to `dash` on Ubuntu
- `sh` fails on bash-specific syntax like `[[ ]]`
- `~/practice/interpreter/detect_shell.sh` reports non-interactive, non-login when run as a script
