# ELF Binaries — Format and Inspection

Every program you run on Linux is an ELF file. Understanding ELF's structure explains how the kernel loads programs, how the dynamic linker resolves symbols, why position-independent code works, and how debugging tools map addresses back to source lines.

## The ELF Format

ELF (Executable and Linkable Format) is the binary format for executables, shared libraries, object files, and core dumps on Linux. Every ELF file starts with the same 16-byte magic header.

```bash
# The first 4 bytes are always: 7f 45 4c 46 (DEL E L F)
xxd /bin/ls | head -2
# 00000000: 7f45 4c46 0201 0100 ...  ELF...

# file identifies ELF type
file /bin/ls
# /bin/ls: ELF 64-bit LSB pie executable, x86-64, dynamically linked, ...
```

### ELF Types

| Type | `e_type` | Description |
|------|---------|-------------|
| ET_EXEC | 2 | Executable (fixed load address) |
| ET_DYN  | 3 | Shared object or PIE executable |
| ET_REL  | 1 | Relocatable object file (.o) |
| ET_CORE | 4 | Core dump |

### Sections vs Segments

ELF has two views of the same file:

- **Sections** (`-S`) — the linker's view: named regions used at link time (`.text`, `.data`, `.symtab`)
- **Segments / program headers** (`-l`) — the kernel's view: memory mappings used at load time (LOAD, DYNAMIC, INTERP)

The kernel reads program headers to map segments into memory. The linker reads section headers to lay out the final binary. After linking, sections are optional — a stripped binary has no section headers but still loads fine.

## readelf — ELF Inspector

`readelf` (from `binutils`) is the primary tool for examining ELF structure.

```bash
# File header: architecture, entry point, offsets to section/program headers
readelf -h /bin/ls

# Program headers (segments): what the kernel maps into memory
readelf -l /bin/ls
# PHDR      — the program header table itself
# INTERP    — path to the dynamic linker (/lib64/ld-linux-x86-64.so.2)
# LOAD      — mappable segment (read+exec for .text, read+write for .data)
# DYNAMIC   — dynamic linking information
# NOTE      — build ID, ABI info
# GNU_STACK — stack permissions (NX bit: RW not RWX)
# GNU_RELRO — read-only after relocation (hardening)

# Section headers: names, sizes, offsets, types
readelf -S /bin/ls | head -40

# Symbol table (static symbols if not stripped)
readelf -s /bin/ls

# Dynamic symbol table (exported/imported symbols)
readelf -s --wide /lib/x86_64-linux-gnu/libc.so.6 | grep " printf"

# Dynamic section: NEEDED libraries, RPATH, etc.
readelf -d /bin/ls

# Relocation entries: GOT/PLT patching
readelf -r /bin/ls

# Everything at once
readelf -a /bin/ls | less
```

### Key ELF Sections

| Section | Contents |
|---------|----------|
| `.text` | Executable machine code |
| `.rodata` | Read-only constants (string literals) |
| `.data` | Initialized writable data (global variables) |
| `.bss` | Uninitialized writable data (zero-filled at load) |
| `.symtab` | Full symbol table (stripped from release builds) |
| `.dynsym` | Dynamic symbol table (minimal symbols needed for dynamic linking) |
| `.strtab` | String table for `.symtab` |
| `.dynstr` | String table for `.dynsym` |
| `.plt` | Procedure Linkage Table (stubs for lazy dynamic linking) |
| `.got` | Global Offset Table (addresses filled in by the dynamic linker) |
| `.debug_*` | DWARF debug information (when compiled with `-g`) |

## nm — Symbol Table Listing

`nm` lists symbols from object files, executables, and libraries.

```bash
# List symbols from an executable (stripped = empty .symtab)
nm /bin/ls

# Dynamic symbols only
nm -D /bin/ls | head -20
nm -D /lib/x86_64-linux-gnu/libc.so.6 | grep " T malloc"

# Sort by address
nm -n /bin/ls

# Demangle C++ names
nm --demangle /usr/lib/x86_64-linux-gnu/libstdc++.so.6 | head -10
```

### Symbol Type Codes

| Code | Meaning |
|------|---------|
| `T` / `t` | Text (code) — uppercase = global, lowercase = local |
| `D` / `d` | Data — initialized global/local data |
| `B` / `b` | BSS — uninitialized data |
| `R` / `r` | Read-only data |
| `U` | Undefined — imported from another object |
| `W` / `w` | Weak symbol — overridable |
| `I` | Indirect function (ifunc — used by glibc) |

## objdump — Disassembly and Object Inspection

`objdump` disassembles machine code and dumps object file contents.

```bash
# Disassemble all code sections
objdump -d /bin/ls | head -60

# Disassemble with source interleaving (requires debug symbols)
objdump -d -S /bin/ls

# Use Intel syntax (easier to read than AT&T)
objdump -d -M intel /bin/ls | head -30

# Show all headers
objdump -x /bin/ls | head -40

# Disassemble a specific section
objdump -d --section=.plt /bin/ls

# Dump raw section content in hex+ASCII
objdump -s --section=.rodata /bin/ls | head -20

# Full symbol table
objdump -t /bin/ls
```

## strings — Extract Printable Strings

```bash
# All printable strings >= 4 chars (default)
strings /bin/ls | head -20

# Longer minimum (reduce noise)
strings -n 8 /bin/ls | grep -i version

# Show offset of each string
strings -t x /bin/ls | head -20   # hex offset
strings -t d /bin/ls | head -20   # decimal offset

# Useful for inspecting unknown binaries
strings /usr/bin/sudo | grep -i "password\|pam\|auth"
```

## Practical Patterns

```bash
# What libraries does this binary need?
readelf -d /bin/ls | grep NEEDED
ldd /bin/ls

# What is the dynamic linker path?
readelf -l /bin/ls | grep interpreter

# Is this binary PIE (position-independent executable)?
readelf -h /bin/ls | grep Type
# ET_DYN = PIE; ET_EXEC = non-PIE

# Has NX (non-executable stack)?
readelf -l /bin/ls | grep GNU_STACK
# RW (no X) = NX enabled; RWE = no NX

# Is RELRO enabled (GOT hardening)?
readelf -l /bin/ls | grep RELRO
# GNU_RELRO present = partial RELRO; BIND_NOW + RELRO = full RELRO

# Is this binary stripped?
file /bin/ls | grep -o "stripped\|not stripped"
readelf -S /bin/ls | grep -q "\.symtab" && echo "has symbols" || echo "stripped"

# Build ID (reproducible build fingerprint)
readelf -n /bin/ls | grep "Build ID"
file /bin/ls | grep BuildID
```

## Further Reading

- [ELF specification (official PDF)](https://refspecs.linuxfoundation.org/elf/elf.pdf) — the System V ABI ELF specification: every header field, section type, segment type, symbol binding/type/visibility code, and relocation type with binary layout diagrams.
- [elf(5) — man7.org](https://man7.org/linux/man-pages/man5/elf.5.html) — the Linux man page for the ELF format: `ElfN_Ehdr`, `ElfN_Phdr`, `ElfN_Shdr`, symbol table entries, and the `/proc/PID/maps` format used to inspect runtime mappings.
- [readelf(1) — man7.org](https://man7.org/linux/man-pages/man1/readelf.1.html) — complete `readelf` flag reference including `--debug-dump` for DWARF sections, `--dyn-syms` for dynamic symbols, `--histogram` for bucket statistics, and `--notes` for build IDs.
- [linux-insides — Program startup](https://0xax.gitbooks.io/linux-insides/content/) — traces how the kernel reads ELF program headers in `load_elf_binary`, maps LOAD segments, reads `PT_INTERP` to find the dynamic linker, and calls `start_thread`.
- [A Whirlwind Tutorial on ELF — muppetlabs](https://www.muppetlabs.com/~breadbox/software/tiny/teensy.html) — famous article building the smallest possible ELF executable, illustrating exactly which fields are required vs optional by walking through the raw bytes.
