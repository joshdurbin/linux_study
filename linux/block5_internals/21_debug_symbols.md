# Debug Symbols and DWARF

A binary without debug symbols is a sequence of addresses. Debug symbols map those addresses back to function names, variable names, source file paths, and line numbers. They're what makes `gdb` show you a backtrace with source lines instead of raw hex.

## What Debug Symbols Are

When you compile with `-g`, the compiler emits extra data describing:
- Which address range corresponds to which function
- Which address in that function corresponds to which source line
- Where local variables live (register or stack offset) at each point
- Type information for every variable

This data is stored in ELF sections named `.debug_*` and encoded in the **DWARF** format.

```bash
# The difference in file size with and without debug symbols
gcc -O2 -o hello_release hello.c
gcc -O2 -g -o hello_debug   hello.c
ls -lh hello_release hello_debug
# hello_debug is typically 3-10x larger

# Check which .debug sections are present
readelf -S hello_debug | grep "\.debug"
# .debug_info   — type and variable descriptions
# .debug_abbrev — abbreviation tables for .debug_info
# .debug_line   — source line → address mapping
# .debug_str    — strings referenced from .debug_info
# .debug_loc    — variable location lists
# .debug_ranges — address ranges for compilation units
# .debug_frame  — call frame information (for unwinding)
```

## Compiler Flags for Debug Symbols

```bash
# -g: DWARF debug info at default level (2)
gcc -g hello.c -o hello

# -g0: no debug info
# -g1: minimal (function names, line numbers; no variable info)
# -g2: default — full info for debuggers
# -g3: includes macro definitions

# Combine with optimization (note: optimized code is harder to debug)
gcc -O2 -g hello.c -o hello_opt   # release binary with symbols (common for production)
gcc -O0 -g hello.c -o hello_dev   # no optimization, easiest to debug

# -fno-omit-frame-pointer: keeps frame pointer in %rbp — crucial for stack unwinding
# (perf, GDB, and bpftrace all benefit from this)
gcc -O2 -g -fno-omit-frame-pointer hello.c -o hello

# Split DWARF (put debug info in a separate .dwo file, faster link)
gcc -g -gsplit-dwarf hello.c -o hello
ls hello.dwo   # separate debug object file
```

## Checking for Debug Symbols

```bash
# file command reports presence of symbols and debug info
file hello_debug
# ELF 64-bit LSB pie executable, ... with debug_info, not stripped

file hello_release
# ELF 64-bit LSB pie executable, ... stripped

# Check for .debug sections
readelf -S hello_debug | grep -q "\.debug_info" && echo "has DWARF" || echo "no DWARF"

# Check if binary is stripped of symbol table
readelf -S hello | grep -q "\.symtab" && echo "has symtab" || echo "stripped"

# Quick summary using eu-readelf (elfutils) if available
eu-readelf --debug-dump=info hello_debug 2>/dev/null | head -30
```

## strip — Removing Symbols

`strip` removes symbol tables and optionally debug info to reduce binary size.

```bash
# Show size before and after
du -sh hello_debug

# Strip only the symbol table (keep DWARF debug info for crash analysis)
strip --strip-debug hello_debug

# Strip everything including debug info
strip --strip-all hello_debug

# Strip unneeded symbols but keep exported ones (for shared libraries)
strip --strip-unneeded libfoo.so

du -sh hello_debug   # much smaller now
```

### Why Keep Separate Debug Info?

Shipping `.debug_info` in production binaries is expensive (large download, memory mapped at load). The standard pattern is:

1. Build with symbols
2. Copy debug info to a separate file
3. Strip the production binary
4. Link the production binary to the debug file via a GNU debug link

```bash
# 1. Compile with full symbols
gcc -g -o myapp myapp.c

# 2. Extract debug info to a separate file
objcopy --only-keep-debug myapp myapp.debug

# 3. Strip the production binary
strip --strip-debug myapp

# 4. Add a link back to the debug file
objcopy --add-gnu-debuglink=myapp.debug myapp

# GDB and crash tools automatically find myapp.debug via the debuglink
readelf -n myapp | grep "debuglink"
```

## addr2line — Address to Source Location

`addr2line` translates a code address into the source file and line number, using the binary's DWARF info.

```bash
# Get the address of a function from nm
ADDR=$(nm hello_debug | awk '/T say_hello/{print $1}')
echo "say_hello is at 0x$ADDR"

# Resolve the address to source
addr2line -e hello_debug 0x$ADDR
# /home/user/practice/elf/hello.c:7

# Also show function name
addr2line -f -e hello_debug 0x$ADDR
# say_hello
# /home/user/practice/elf/hello.c:7

# Demangle C++ names
addr2line -Cf -e myapp 0x4006ab

# Inline functions: -i shows the full inline chain
addr2line -Cfi -e hello_debug 0x$ADDR
```

`addr2line` is essential when you have a crash address from a log, core dump, or kernel panic and want to find the source line.

## debuginfo Packages — System Library Symbols

Production system binaries (`/bin/ls`, `/lib/libc.so.6`) are stripped. Distros ship separate debug packages:

```bash
# Ubuntu: enable debug symbol repos
echo "deb http://ddebs.ubuntu.com $(lsb_release -cs) main restricted universe multiverse" \
    | sudo tee /etc/apt/sources.list.d/ddebs.list
sudo apt-get install -y ubuntu-dbgsym-keyring
sudo apt-get update

# Install debug symbols for a package
sudo apt-get install -y coreutils-dbgsym    # debug symbols for ls, cp, etc.
sudo apt-get install -y libc6-dbg           # glibc debug symbols

# Debug symbols are installed to /usr/lib/debug/
ls /usr/lib/debug/usr/bin/ls 2>/dev/null

# GDB automatically finds them via the build ID
readelf -n /bin/ls | grep "Build ID"
# The .build-id/<xx>/<rest>.debug path under /usr/lib/debug is the lookup key
```

### debuginfod — Network Symbol Server

Modern systems use `debuginfod` to fetch symbols on demand:

```bash
# Check if debuginfod is configured
echo $DEBUGINFOD_URLS

# Ubuntu's debuginfod server
export DEBUGINFOD_URLS="https://debuginfod.ubuntu.com"

# GDB will automatically fetch symbols when needed
# gdb /bin/ls → symbols fetched automatically from debuginfod
```

## Reading DWARF Directly

```bash
# Dump DWARF debug_info (very verbose)
readelf --debug-dump=info hello_debug | head -60

# Dump the line number program
readelf --debug-dump=line hello_debug | head -40

# objdump DWARF dump
objdump --dwarf=info hello_debug | head -40
objdump --dwarf=decodedline hello_debug | head -20   # human-readable line table
```

## Further Reading

- [DWARF 5 standard](https://dwarfstd.org/dwarf5std.html) — the official DWARF 5 specification: `.debug_info` structure, `.debug_line` line number program, `.debug_loc` variable location lists, and call frame information (`.debug_frame`) used by unwinders.
- [addr2line(1) — man7.org](https://man7.org/linux/man-pages/man1/addr2line.1.html) — complete reference for `addr2line` including the `-f` (function names), `-C` (demangle), `-i` (inline chain), and `-p` (pretty-print) flags used to resolve crash addresses to source lines.
- [objcopy(1) — man7.org](https://man7.org/linux/man-pages/man1/objcopy.1.html) — documents `--only-keep-debug`, `--strip-debug`, `--add-gnu-debuglink`, and section manipulation — the exact operations used in the split-debuginfo workflow in this lesson.
- [GCC debugging options](https://gcc.gnu.org/onlinedocs/gcc/Debugging-Options.html) — official GCC reference for `-g`, `-g0`–`-g3`, `-gdwarf-5`, `-gsplit-dwarf`, `-fno-omit-frame-pointer`, and `-fsanitize` options that affect debug symbol quality.
- [LWN — Debuginfo packages and debuginfod](https://lwn.net/Articles/664290/) — explains the debuginfo package ecosystem, build IDs as lookup keys, and the `debuginfod` server protocol that allows GDB and `perf` to fetch symbols on demand without installing debug packages.
