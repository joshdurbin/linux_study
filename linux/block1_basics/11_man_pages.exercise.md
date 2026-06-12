# Exercise: Man Pages and Documentation

## Tasks

1. **Sections**: Find the man page in the right section for each of these — note the section number and one-line description:
   ```bash
   {
     echo "=== passwd command ==="
     man 1 passwd 2>/dev/null | head -5 || echo "not found"
     echo "=== passwd file format ==="
     man 5 passwd 2>/dev/null | head -5 || echo "not found"
     echo "=== open syscall ==="
     man 2 open 2>/dev/null | head -5 || echo "not found"
     echo "=== signal reference ==="
     man 7 signal 2>/dev/null | head -5 || echo "not found"
   } > ~/practice/man_sections.txt
   ```

2. **apropos search**: Find man pages related to "compress" and "archive":
   ```bash
   sudo mandb -q 2>/dev/null || true
   {
     echo "=== compress ==="
     apropos compress 2>/dev/null | head -10
     echo "=== archive ==="
     apropos archive 2>/dev/null | head -10
   } > ~/practice/man_apropos.txt
   ```

3. **whatis lookup**: Get one-line descriptions for 5 commands:
   ```bash
   for cmd in ls grep find ssh tar; do
     whatis "$cmd" 2>/dev/null || echo "$cmd: (whatis not available)"
   done > ~/practice/man_whatis.txt
   ```

4. **Reading a man page**: Extract the SYNOPSIS section from `man grep`:
   ```bash
   man grep | col -bx | awk '/^SYNOPSIS/,/^[A-Z]/' | head -15 \
     > ~/practice/man_grep_synopsis.txt
   ```

5. **System call lookup**: Read the man page for the `read` system call and save the first 20 lines of the DESCRIPTION:
   ```bash
   man 2 read 2>/dev/null | col -bx | \
     awk '/^DESCRIPTION/,/^[A-Z][A-Z]/' | head -20 \
     > ~/practice/man_syscall_read.txt || \
   echo "man section 2 not available in this container" \
     > ~/practice/man_syscall_read.txt
   ```

## Hints

- `man -k keyword` and `apropos keyword` are the same thing
- `col -bx` strips backspace-encoded bold/underline formatting from man output — useful when piping
- Section 2 (system calls) may not be available if `manpages-dev` isn't installed
- `help cd` shows documentation for bash builtins like `cd`, `source`, `export` — these have no man pages
