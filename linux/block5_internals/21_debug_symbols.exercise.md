# Exercise: Debug Symbols and DWARF

## Setup

```bash
mkdir -p ~/practice/debug_symbols
sudo apt-get install -y binutils gcc 2>/dev/null || true
```

## Task 1: Compile with and Without Debug Symbols

```bash
cat > ~/practice/debug_symbols/sample.c << 'EOF'
#include <stdio.h>

typedef struct {
    int x;
    int y;
} Point;

static int add(int a, int b) {
    return a + b;
}

Point make_point(int x, int y) {
    Point p = {x, y};
    return p;
}

int main(void) {
    int result = add(3, 4);
    Point pt = make_point(10, 20);
    printf("result=%d point=(%d,%d)\n", result, pt.x, pt.y);
    return 0;
}
EOF

# Compile three variants
gcc -O0 -g     -o ~/practice/debug_symbols/sample_debug   ~/practice/debug_symbols/sample.c
gcc -O2        -o ~/practice/debug_symbols/sample_release ~/practice/debug_symbols/sample.c
gcc -O2 -g     -o ~/practice/debug_symbols/sample_opt     ~/practice/debug_symbols/sample.c

echo "File sizes:"
ls -lh ~/practice/debug_symbols/sample_*
```

## Task 2: Inspect Debug Sections with readelf

```bash
echo "=== Debug sections in sample_debug ==="
readelf -S ~/practice/debug_symbols/sample_debug | grep "debug\|\.sym"

echo ""
echo "=== Debug sections in sample_release (should be empty) ==="
readelf -S ~/practice/debug_symbols/sample_release | grep "debug\|\.sym" || echo "(none — as expected)"
```

## Task 3: Compare file Command Output

```bash
echo "=== sample_debug ===" && file ~/practice/debug_symbols/sample_debug
echo ""
echo "=== sample_release ===" && file ~/practice/debug_symbols/sample_release
echo ""
echo "=== sample_opt ===" && file ~/practice/debug_symbols/sample_opt
```

Note: the `file` command reports "with debug_info, not stripped" vs "stripped".

## Task 4: Use addr2line to Find Source Lines

```bash
# Find the address of make_point from nm (block5/20)
ADDR=$(nm ~/practice/debug_symbols/sample_debug | awk '/T make_point/{print $1}')
echo "make_point address: 0x${ADDR}"

# Resolve to source file and line
addr2line -f -e ~/practice/debug_symbols/sample_debug "0x${ADDR}"
# Should show: make_point   ~/practice/debug_symbols/sample.c:<line>

# Resolve main's address too
MAIN_ADDR=$(nm ~/practice/debug_symbols/sample_debug | awk '/T main$/{print $1}')
addr2line -f -e ~/practice/debug_symbols/sample_debug "0x${MAIN_ADDR}"
```

## Task 5: View the DWARF Line Table

```bash
# Show the source-line to address mapping table
objdump --dwarf=decodedline ~/practice/debug_symbols/sample_debug | head -40
```

You should see each line of `sample.c` mapped to an address range.

## Task 6: Strip and Separate Debug Info

```bash
cp ~/practice/debug_symbols/sample_debug ~/practice/debug_symbols/sample_prod

# Step 1: Extract debug info to a separate file
objcopy --only-keep-debug \
    ~/practice/debug_symbols/sample_prod \
    ~/practice/debug_symbols/sample_prod.debug

# Step 2: Strip the production binary
strip --strip-debug ~/practice/debug_symbols/sample_prod

# Step 3: Add a GNU debug link back to the debug file
objcopy --add-gnu-debuglink=~/practice/debug_symbols/sample_prod.debug \
    ~/practice/debug_symbols/sample_prod

echo "Sizes after separation:"
ls -lh ~/practice/debug_symbols/sample_prod ~/practice/debug_symbols/sample_prod.debug

echo ""
echo "Is sample_prod stripped?"
file ~/practice/debug_symbols/sample_prod

echo ""
echo "Does sample_prod.debug still have debug sections?"
readelf -S ~/practice/debug_symbols/sample_prod.debug | grep "debug" | wc -l
```

## Task 7: addr2line with the Stripped + Linked Binary

```bash
ADDR=$(nm ~/practice/debug_symbols/sample_debug | awk '/T make_point/{print $1}')

echo "addr2line on the stripped binary (no DWARF — won't resolve):"
addr2line -f -e ~/practice/debug_symbols/sample_prod "0x${ADDR}" 2>&1

echo ""
echo "addr2line on the separate debug file (should resolve):"
addr2line -f -e ~/practice/debug_symbols/sample_prod.debug "0x${ADDR}" 2>&1
```

## Expected Outcome

- `sample_debug` has multiple `.debug_*` sections; `sample_release` has none
- `file` reports "with debug_info, not stripped" for debug builds
- `addr2line -f` maps `make_point`'s address to `sample.c` with the correct line number
- `objdump --dwarf=decodedline` shows the line-number table
- `sample_prod` is stripped (smaller, no DWARF), `sample_prod.debug` retains all debug sections
- `addr2line` resolves addresses from the `.debug` file but not from the stripped binary
