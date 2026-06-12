# Exercise: ELF Binaries

## Setup

```bash
mkdir -p ~/practice/elf
sudo apt-get install -y binutils gcc 2>/dev/null || true
```

## Task 1: Inspect the ELF Header

```bash
# Read the file header of /bin/ls
readelf -h /bin/ls

# Check ELF type, architecture, entry point, and number of headers
readelf -h /bin/ls | grep -E "Type:|Machine:|Entry|program headers|section headers"

# Verify the magic bytes directly
xxd /bin/ls | head -1
```

## Task 2: Explore Program Headers (Segments)

```bash
readelf -l /bin/ls

# Identify which segment types are present
readelf -l /bin/ls | grep -oE "^\s+[A-Z_]+" | sort -u

# Find the interpreter (dynamic linker) path
readelf -l /bin/ls | grep -A1 "INTERP"

# Is NX enabled? (stack should be RW, not RWX)
readelf -l /bin/ls | grep "GNU_STACK"
```

## Task 3: Explore Section Headers

```bash
# List all sections with types and sizes
readelf -S /bin/ls | grep -v "^\[Nr\]\|^Key\|^ \[" | head -30

# Is the binary stripped? (.symtab section present?)
readelf -S /bin/ls | grep -E "\.symtab|\.strtab"
file /bin/ls | grep -oE "stripped|not stripped"
```

## Task 4: Inspect Dynamic Symbols

```bash
# What does ls import from shared libraries?
nm -D /bin/ls | grep "^[[:space:]]*U " | head -20

# What does libc export that ls uses?
nm -D /bin/ls | grep " U " | awk '{print $2}' | sort | head -10
```

## Task 5: Compile a Test Binary and Compare

```bash
cat > ~/practice/elf/hello.c << 'EOF'
#include <stdio.h>

int global_var = 42;
static int local_var = 7;

void say_hello(const char *name) {
    printf("Hello, %s! global=%d\n", name, global_var);
}

int main(void) {
    say_hello("world");
    return 0;
}
EOF

# Compile with debug symbols (not stripped)
gcc -g -o ~/practice/elf/hello ~/practice/elf/hello.c

# Compile stripped
gcc -o ~/practice/elf/hello_stripped ~/practice/elf/hello.c
strip ~/practice/elf/hello_stripped

echo "=== With symbols ===" && file ~/practice/elf/hello
echo "=== Stripped ===" && file ~/practice/elf/hello_stripped
```

## Task 6: Examine Symbols with nm

```bash
# List all symbols in the unstripped binary
nm ~/practice/elf/hello

# Identify the symbol types:
# T = global function (text section)
# t = local function
# D = initialized global data
# d = local initialized data
# U = undefined (imported)

nm ~/practice/elf/hello | grep -E " T | D | U "

# Compare: stripped has no .symtab
nm ~/practice/elf/hello_stripped 2>&1
nm -D ~/practice/elf/hello_stripped   # dynamic symbols still present
```

## Task 7: Disassemble with objdump

```bash
# Disassemble the main function (Intel syntax)
objdump -d -M intel ~/practice/elf/hello | grep -A 30 "<main>:"

# See string literals in .rodata
objdump -s --section=.rodata ~/practice/elf/hello

# View the PLT (dynamic call stubs)
objdump -d --section=.plt ~/practice/elf/hello
```

## Task 8: Extract Strings and Check PIE/RELRO

```bash
# Strings in the binary
strings ~/practice/elf/hello | grep -E "Hello|world|global"

# Is it PIE?
readelf -h ~/practice/elf/hello | grep "Type"
# ET_DYN = PIE executable (gcc default on modern Ubuntu)

# RELRO status
readelf -l ~/practice/elf/hello | grep "GNU_RELRO"
readelf -d ~/practice/elf/hello | grep "BIND_NOW"
```

## Expected Outcome

- `readelf -h /bin/ls` shows ELF type, entry point, and header counts
- Program headers show INTERP (dynamic linker path), LOAD segments, and GNU_STACK with NX
- `~/practice/elf/hello` is compiled with `-g` and has `.symtab`
- `~/practice/elf/hello_stripped` shows "stripped" and `nm` returns "no symbols"
- `nm ~/practice/elf/hello` shows `T say_hello`, `D global_var`, and `U printf`
- `objdump -d` shows disassembly of main with recognizable function calls
