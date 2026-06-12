#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: addr2line is available
check "addr2line is available" \
  "command -v addr2line > /dev/null 2>&1"

# Check 2: objcopy is available
check "objcopy is available" \
  "command -v objcopy > /dev/null 2>&1"

# Check 3: strip is available
check "strip is available" \
  "command -v strip > /dev/null 2>&1"

# Check 4: gcc is available (from block5/20)
check "gcc is available" \
  "command -v gcc > /dev/null 2>&1"

# Check 5: practice/debug_symbols directory exists
check "~/practice/debug_symbols directory exists" \
  "[ -d \$HOME/practice/debug_symbols ]"

# Check 6: sample.c exists
check "sample.c exists" \
  "[ -f \$HOME/practice/debug_symbols/sample.c ]"

# Check 7: sample_debug exists and has DWARF debug_info
check "sample_debug exists with .debug_info section" \
  "[ -f \$HOME/practice/debug_symbols/sample_debug ] && \
   readelf -S \$HOME/practice/debug_symbols/sample_debug 2>/dev/null | grep -q '\.debug_info'"

# Check 8: sample_release exists and has no .debug sections
check "sample_release exists with no .debug sections" \
  "[ -f \$HOME/practice/debug_symbols/sample_release ] && \
   ! readelf -S \$HOME/practice/debug_symbols/sample_release 2>/dev/null | grep -q '\.debug_info'"

# Check 9: sample_debug has .symtab (not stripped)
check "sample_debug has .symtab (not stripped)" \
  "readelf -S \$HOME/practice/debug_symbols/sample_debug 2>/dev/null | grep -q '\.symtab'"

# Check 10: addr2line resolves make_point to a source file
check "addr2line resolves make_point address to source file" \
  "ADDR=\$(nm \$HOME/practice/debug_symbols/sample_debug 2>/dev/null | awk '/T make_point/{print \$1}'); \
   [ -n \"\$ADDR\" ] && \
   addr2line -f -e \$HOME/practice/debug_symbols/sample_debug \"0x\${ADDR}\" 2>/dev/null | \
   grep -q 'sample\.c'"

# Check 11: sample_prod.debug exists and has debug sections
check "sample_prod.debug exists and contains debug sections" \
  "[ -f \$HOME/practice/debug_symbols/sample_prod.debug ] && \
   readelf -S \$HOME/practice/debug_symbols/sample_prod.debug 2>/dev/null | grep -q '\.debug'"

# Check 12: sample_prod is stripped
check "sample_prod is stripped (no .debug_info)" \
  "[ -f \$HOME/practice/debug_symbols/sample_prod ] && \
   ! readelf -S \$HOME/practice/debug_symbols/sample_prod 2>/dev/null | grep -q '\.debug_info'"

# Check 13: sample_prod.debug is smaller than sample_debug (symbols extracted, not duplicated)
check "sample_prod is smaller than sample_debug after stripping" \
  "[ \$(stat -c%s \$HOME/practice/debug_symbols/sample_prod 2>/dev/null || echo 0) -lt \
     \$(stat -c%s \$HOME/practice/debug_symbols/sample_debug 2>/dev/null || echo 1) ]"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
