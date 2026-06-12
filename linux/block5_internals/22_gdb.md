# GDB — The GNU Debugger

GDB lets you stop a running program at any point, inspect its state (registers, memory, variables, call stack), and step through it instruction by instruction. It works on live processes (attaching with ptrace), pre-compiled binaries you launch yourself, and post-mortem core dump files.

## How GDB Works Under the Hood

GDB uses `ptrace(2)` (block5/03) to control the target process:

```
gdb attaches:   ptrace(PTRACE_ATTACH, target_pid, ...)
set breakpoint: ptrace(PTRACE_POKETEXT, ...) replaces byte with 0xCC (INT3)
target hits BP: kernel delivers SIGTRAP to gdb
gdb reads state: ptrace(PTRACE_GETREGS, ...) / ptrace(PTRACE_PEEKDATA, ...)
gdb continues:  ptrace(PTRACE_CONT, ...)
```

This explains why `strace` and `gdb` cannot both attach to the same process simultaneously, and why some containers restrict ptrace via seccomp or capabilities.

## Starting GDB

```bash
# Debug a program you launch
gdb ./myapp

# Attach to a running process
gdb -p 1234
sudo gdb -p 1234   # root required for cross-user attach

# Post-mortem: analyze a core dump
gdb ./myapp core
gdb ./myapp /tmp/core.1234

# Run with arguments
gdb --args ./myapp arg1 arg2

# Batch mode (non-interactive — useful for scripting)
gdb -batch -ex "run" -ex "bt" ./myapp
```

## GDB Commands Reference

### Execution Control

```
run [args]          Start the program (r)
continue            Resume after a stop (c)
step                Step one source line, into function calls (s)
next                Step one source line, over function calls (n)
stepi               Step one machine instruction (si)
nexti               Step one instruction, over calls (ni)
finish              Run until the current function returns (fin)
until <line>        Run until source line
jump <addr>         Jump to address (dangerous — skips cleanup)
kill                Kill the running program
quit                Exit GDB (q)
```

### Breakpoints

```
break main              Set breakpoint at function (b)
break file.c:42         Break at line 42 of file.c
break *0x4005f0         Break at address
break foo if x > 5      Conditional breakpoint
info breakpoints        List all breakpoints (i b)
delete 2                Delete breakpoint 2
disable 2 / enable 2    Disable/enable without deleting
tbreak main             Temporary breakpoint (deletes after first hit)
```

### Watchpoints — Break on Data Changes

```
watch x             Break when variable x is written
rwatch x            Break when x is read
awatch x            Break on any access to x
info watchpoints    List watchpoints
```

Watchpoints are invaluable for tracking down memory corruption: find out exactly when and where a variable gets an unexpected value.

### Inspecting State

```
backtrace           Full call stack (bt)
backtrace full      Stack with local variables
frame 3             Switch to frame 3 in the call stack (f 3)
up / down           Move up/down one frame
info locals         Local variables in current frame
info args           Function arguments in current frame
info registers      All register values (i r)
info registers rip rsp rbp   Specific registers

print x             Print variable value (p)
print *ptr          Dereference pointer
print ptr->field    Struct field access
print arr[0]@10     Print 10 elements of arr starting at [0]
display x           Print x automatically after every step
undisplay 1         Stop auto-displaying item 1

x/10xg $rsp         Examine memory: 10 hex giant-words at rsp
x/20i $rip          Examine 20 instructions at instruction pointer
x/s 0x4006a0        Examine as string
# Format: x/<count><format><size>
# Formats: x=hex, d=decimal, u=unsigned, o=octal, t=binary, a=address, s=string, i=instruction
# Sizes: b=byte, h=halfword(2), w=word(4), g=giant(8)
```

### Source and Disassembly

```
list                Show source around current line (l)
list main           Show source around function
disassemble         Disassemble current function (disas)
disassemble main    Disassemble function by name
disassemble /m main Show source interleaved with assembly
set disassembly-flavor intel   Switch to Intel syntax
```

## TUI Mode — Text User Interface

GDB's TUI mode splits the terminal into panes showing source, assembly, and registers simultaneously.

```bash
# Start in TUI mode
gdb -tui ./myapp

# Or toggle TUI at any time
Ctrl-X A        # toggle TUI on/off
Ctrl-X 2        # split: source + assembly
Ctrl-X 1        # single window

# Layout commands
layout src      # source code
layout asm      # assembly
layout regs     # registers
layout split    # source + asm
tui reg all     # show all registers
tui reg float   # floating point registers

# Navigate source window with arrow keys
# Focus: Ctrl-X O toggles focus between TUI windows
```

## Core Dumps — Post-Mortem Debugging

A core dump is a snapshot of a crashed process's memory, registers, and state. Invaluable for diagnosing crashes in production where you can't attach a debugger live.

### Enabling Core Dumps

```bash
# Check current core dump size limit (block3/09 ulimits)
ulimit -c

# Enable (unlimited size)
ulimit -c unlimited

# Check/set the core dump filename pattern
cat /proc/sys/kernel/core_pattern
# Default: "core" (writes to current directory)
# Modern Ubuntu uses systemd-coredump:
# |/usr/lib/systemd/systemd-coredump %P %u %g %s %t %c %h

# Set a pattern with PID and program name
echo "/tmp/cores/core.%e.%p" | sudo tee /proc/sys/kernel/core_pattern
sudo mkdir -p /tmp/cores
```

**core_pattern % specifiers:**

| Specifier | Meaning |
|-----------|---------|
| `%e` | Executable filename |
| `%p` | PID |
| `%t` | Unix timestamp |
| `%s` | Signal number |
| `%u` | UID |
| `%h` | Hostname |

### Generating Core Dumps

```bash
# Method 1: Let a crash happen (segfault, abort, etc.)
./buggy_program    # crashes → core dump written per core_pattern

# Method 2: Force a core dump from a running process (non-destructive)
gcore -o /tmp/myapp.core $(pgrep myapp)

# Method 3: Send SIGABRT
kill -ABRT $(pgrep myapp)   # kills the process and generates a core
```

### Analyzing a Core Dump

```bash
# Open the core dump with the matching binary
gdb ./myapp core

# Or with a PID-suffixed core file
gdb ./myapp /tmp/cores/core.myapp.1234

# Inside GDB, the program is "frozen" at the crash point:
(gdb) backtrace          # see the call stack at time of crash
(gdb) frame 0            # go to the crashing frame
(gdb) info locals        # variables in the crashing function
(gdb) print errno        # check errno value
(gdb) info registers     # register state at crash

# Find the crash address and look it up in source
(gdb) x/1i $rip          # instruction at crash

# List all threads and their stacks
(gdb) info threads
(gdb) thread apply all bt
```

## Attaching to Running Processes

```bash
# Find the PID
pgrep nginx

# Attach (will pause the process)
sudo gdb -p $(pgrep nginx | head -1)
(gdb) backtrace       # see what it was doing when you attached
(gdb) info threads    # all threads
(gdb) thread apply all bt    # all thread stacks

# Detach without killing the process
(gdb) detach
(gdb) quit

# Or: continue first, then detach
(gdb) continue
# Ctrl-C to interrupt again
(gdb) detach
```

## Practical Debugging Patterns

```bash
# Find a segfault: run until crash, then inspect
gdb ./myapp
(gdb) run
# ... SIGSEGV
(gdb) backtrace
(gdb) frame 1
(gdb) print *bad_pointer

# Debug a hang: attach, see what it's blocked on
sudo gdb -p $(pgrep hung_app)
(gdb) info threads
(gdb) thread apply all bt    # find the thread blocked in a lock/syscall

# Find a memory corruption: use watchpoint
gdb ./myapp
(gdb) break main
(gdb) run
(gdb) watch global_counter    # stop when global_counter changes
(gdb) continue               # runs until counter changes
(gdb) backtrace              # shows who changed it

# Print all local variables in every frame
(gdb) backtrace full
```

## Further Reading

- [GDB manual](https://sourceware.org/gdb/current/onlinedocs/gdb/) — the complete GDB documentation: all commands in this lesson plus Python scripting, pretty printers, non-stop mode, remote debugging (`gdbserver`), and the GDB/MI machine interface.
- [ptrace(2) — man7.org](https://man7.org/linux/man-pages/man2/ptrace.2.html) — documents every `PTRACE_*` operation: `PTRACE_ATTACH`, `PTRACE_GETREGS`, `PTRACE_POKETEXT` (for breakpoints), hardware watchpoints via debug registers, and `PTRACE_SEIZE` for non-stop debugging.
- [core(5) — man7.org](https://man7.org/linux/man-pages/man5/core.5.html) — documents the core dump file format (ELF `ET_CORE`), `core_pattern` `%`-specifiers, `/proc/PID/coredump_filter` for controlling which mappings are included, and `systemd-coredump` integration.
- [Julia Evans — How to look at the stack in GDB](https://jvns.ca/blog/2021/05/17/how-to-look-at-the-stack-in-gdb/) — practical GDB guide with annotated examples of `backtrace`, `frame`, `info locals`, `x/` memory examination, and TUI mode — exactly the commands used in this lesson.
- [GDB cheat sheet — darkdust](https://darkdust.net/files/GDB%20Cheat%20Sheet.pdf) — single-page reference for all GDB commands organized by category: execution control, breakpoints, watchpoints, inspecting state, TUI, and core dump analysis.
