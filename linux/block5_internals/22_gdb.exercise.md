# Exercise: GDB — The GNU Debugger

## Setup

```bash
mkdir -p ~/practice/gdb
sudo apt-get install -y gdb gcc 2>/dev/null || true
```

## Task 1: Compile a Debuggable Program

```bash
cat > ~/practice/gdb/debug_me.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int factorial(int n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}

void fill_buffer(char *buf, int size) {
    for (int i = 0; i < size; i++) {
        buf[i] = 'A' + (i % 26);
    }
    buf[size - 1] = '\0';
}

int main(int argc, char *argv[]) {
    int n = 5;
    if (argc > 1) n = atoi(argv[1]);

    printf("factorial(%d) = %d\n", n, factorial(n));

    char buffer[32];
    fill_buffer(buffer, sizeof(buffer));
    printf("buffer: %s\n", buffer);

    return 0;
}
EOF

# Compile with debug symbols and no optimization
gcc -O0 -g -o ~/practice/gdb/debug_me ~/practice/gdb/debug_me.c
echo "Compiled: $(file ~/practice/gdb/debug_me | grep -o 'with debug_info\|not stripped')"
```

## Task 2: Basic GDB Session — Breakpoints and Stepping

```bash
# Run GDB in batch mode so it can be automated
gdb -batch \
    -ex "break main" \
    -ex "run 6" \
    -ex "info locals" \
    -ex "next" \
    -ex "print n" \
    -ex "continue" \
    ~/practice/gdb/debug_me 2>/dev/null

echo "Exit code: $?"
```

## Task 3: Inspect the Call Stack

```bash
# Break inside factorial and print the full backtrace
gdb -batch \
    -ex "break factorial" \
    -ex "run 4" \
    -ex "backtrace" \
    -ex "info args" \
    -ex "continue" \
    ~/practice/gdb/debug_me 2>/dev/null
```

The backtrace shows the recursive calls: `main → factorial(4) → factorial(3) → ...`

## Task 4: Examine Memory

```bash
gdb -batch \
    -ex "break fill_buffer" \
    -ex "run" \
    -ex "info args" \
    -ex "next" \
    -ex "next" \
    -ex "x/32cb buf" \
    -ex "continue" \
    ~/practice/gdb/debug_me 2>/dev/null
```

`x/32cb buf` prints 32 bytes at the `buf` pointer as characters.

## Task 5: Write a GDB Script

```bash
cat > ~/practice/gdb/inspect.gdb << 'EOF'
# GDB script: set breakpoint, run, inspect, continue
set pagination off
break factorial
commands
  silent
  printf "factorial called with n=%d\n", n
  continue
end
run 5
quit
EOF

gdb -batch -x ~/practice/gdb/inspect.gdb ~/practice/gdb/debug_me 2>/dev/null
```

## Task 6: Core Dumps

```bash
# Compile a program that crashes
cat > ~/practice/gdb/crash_me.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>

void bad_function(void) {
    int *null_ptr = NULL;
    *null_ptr = 42;    /* segfault */
}

int main(void) {
    printf("About to crash...\n");
    bad_function();
    return 0;
}
EOF

gcc -O0 -g -o ~/practice/gdb/crash_me ~/practice/gdb/crash_me.c

# Enable core dumps and set output location
ulimit -c unlimited
mkdir -p /tmp/cores
echo "/tmp/cores/core.%e.%p" | sudo tee /proc/sys/kernel/core_pattern 2>/dev/null || \
    echo "Note: core_pattern requires root; using default location"

# Run the crashing program
cd ~/practice/gdb && ./crash_me; echo "Exit: $?"

# Find the core dump
ls -lh /tmp/cores/ 2>/dev/null || ls -lh ~/practice/gdb/core* 2>/dev/null || \
    echo "Core dump may be handled by systemd-coredump — check: coredumpctl list"
```

## Task 7: Analyze the Core Dump (or Run Under GDB Directly)

```bash
# Method A: analyze a core dump if one was created
CORE=$(ls /tmp/cores/core.crash_me.* 2>/dev/null | head -1)
if [ -n "$CORE" ]; then
    echo "Analyzing core: $CORE"
    gdb -batch \
        -ex "backtrace" \
        -ex "frame 0" \
        -ex "info locals" \
        ~/practice/gdb/crash_me "$CORE" 2>/dev/null
fi

# Method B: run directly under GDB to catch the crash
gdb -batch \
    -ex "run" \
    -ex "backtrace" \
    -ex "frame 1" \
    -ex "info locals" \
    ~/practice/gdb/crash_me 2>/dev/null
```

GDB should show the crash in `bad_function` at the `*null_ptr = 42` line.

## Task 8: Confirm ptrace Is Being Used

```bash
# Verify that GDB uses ptrace(PTRACE_ATTACH) to control the process
strace -e trace=ptrace gdb -batch -ex "run" -ex "quit" \
    ~/practice/gdb/debug_me 2>&1 | grep "ptrace" | head -10
```

This confirms the lesson's explanation: GDB is built on `ptrace(2)` (block5/03).

## Expected Outcome

- `debug_me` compiles with `-g` and shows "with debug_info, not stripped"
- GDB batch breakpoint on `main` runs and shows local variables
- Backtrace inside `factorial(4)` shows the recursive call chain
- `x/32cb buf` prints buffer contents as characters
- `inspect.gdb` script prints a message on each `factorial` call
- `crash_me` crashes with a segfault and GDB's backtrace points to `bad_function`
- `strace` on GDB reveals `ptrace(PTRACE_ATTACH, ...)` calls
