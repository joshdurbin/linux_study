#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: readelf is available
check "readelf is available" \
  "command -v readelf > /dev/null 2>&1"

# Check 2: nm is available
check "nm is available" \
  "command -v nm > /dev/null 2>&1"

# Check 3: objdump is available
check "objdump is available" \
  "command -v objdump > /dev/null 2>&1"

# Check 4: strings is available
check "strings is available" \
  "command -v strings > /dev/null 2>&1"

# Check 5: gcc is available
check "gcc is available" \
  "command -v gcc > /dev/null 2>&1"

# Check 6: readelf can read ELF header of /bin/ls
check "readelf -h reads /bin/ls ELF header" \
  "readelf -h /bin/ls 2>/dev/null | grep -q 'ELF Header'"

# Check 7: readelf shows program headers with LOAD segment
check "readelf -l shows LOAD segment in /bin/ls" \
  "readelf -l /bin/ls 2>/dev/null | grep -q 'LOAD'"

# Check 8: readelf shows INTERP (dynamic linker) in /bin/ls
check "readelf -l shows INTERP segment (dynamic linker) in /bin/ls" \
  "readelf -l /bin/ls 2>/dev/null | grep -q 'INTERP'"

# Check 9: nm -D lists dynamic symbols
check "nm -D lists dynamic symbols from /bin/ls" \
  "nm -D /bin/ls 2>/dev/null | grep -q ' U '"

# Check 10: practice/elf directory exists
check "~/practice/elf directory exists" \
  "[ -d \$HOME/practice/elf ]"

# Check 11: hello.c exists
check "hello.c exists" \
  "[ -f \$HOME/practice/elf/hello.c ]"

# Check 12: hello binary was compiled with debug symbols
check "hello binary exists and has debug symbols (.symtab)" \
  "[ -f \$HOME/practice/elf/hello ] && \
   readelf -S \$HOME/practice/elf/hello 2>/dev/null | grep -q '\.symtab'"

# Check 13: hello_stripped has no .symtab
check "hello_stripped exists and is stripped (no .symtab)" \
  "[ -f \$HOME/practice/elf/hello_stripped ] && \
   ! readelf -S \$HOME/practice/elf/hello_stripped 2>/dev/null | grep -q '\.symtab'"

# Check 14: nm finds global_var symbol in hello
check "nm finds global_var D symbol in hello" \
  "nm \$HOME/practice/elf/hello 2>/dev/null | grep -q 'global_var'"

# Check 15: nm finds say_hello T symbol in hello
check "nm finds say_hello T (text) symbol in hello" \
  "nm \$HOME/practice/elf/hello 2>/dev/null | grep -qE '[Tt] say_hello'"

# Check 16: objdump can disassemble hello
check "objdump -d disassembles hello without error" \
  "objdump -d \$HOME/practice/elf/hello > /dev/null 2>&1"

# Check 17: strings finds embedded string in hello
check "strings finds 'Hello' in hello binary" \
  "strings \$HOME/practice/elf/hello 2>/dev/null | grep -q 'Hello'"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
