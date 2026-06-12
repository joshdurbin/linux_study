# Vim Basics

Vim is a modal text editor available on virtually every Unix system. The key insight: vim has separate modes for navigation and editing. Once that clicks, it becomes very fast.

## Modes

| Mode | How to enter | Purpose |
|------|-------------|---------|
| Normal | `Esc` (always) | Navigation, commands |
| Insert | `i`, `a`, `o`, etc. | Type text |
| Visual | `v`, `V`, `Ctrl-v` | Select text |
| Command | `:` | Save, quit, search/replace |

You always start in Normal mode. Press `Esc` to return to Normal from any mode.

## Opening and Closing

```
vim file.txt          # open or create file
vim +42 file.txt      # open at line 42
vim +/pattern file.txt  # open at first match of pattern

:w          # write (save)
:w file.txt # save to new filename
:q          # quit (fails if unsaved changes)
:q!         # quit and discard changes
:wq         # write and quit
:x          # write (only if changed) and quit
ZZ          # shorthand for :wq
ZQ          # shorthand for :q!
```

## Normal Mode: Navigation

### Character and Line

```
h  j  k  l     # left, down, up, right
0              # beginning of line
^              # first non-blank character of line
$              # end of line
```

### Word Movement

```
w    # forward one word (start)
W    # forward one WORD (whitespace-delimited)
b    # back one word
B    # back one WORD
e    # end of current/next word
```

### File Navigation

```
gg   # go to first line
G    # go to last line
42G  # go to line 42
Ctrl-f  # page forward
Ctrl-b  # page back
Ctrl-d  # half-page down
Ctrl-u  # half-page up
H    # top of screen
M    # middle of screen
L    # bottom of screen
```

## Normal Mode: Editing

### Entering Insert Mode

```
i    # insert before cursor
I    # insert at beginning of line
a    # append after cursor
A    # append at end of line
o    # open new line below and insert
O    # open new line above and insert
```

### Delete / Change

```
x    # delete character under cursor
X    # delete character before cursor
dd   # delete (cut) current line
3dd  # delete 3 lines
D    # delete to end of line
dw   # delete word
d$   # delete to end of line
cc   # change (delete + insert) line
cw   # change word
C    # change to end of line
r    # replace single character (stays in Normal)
R    # replace mode (overtype)
```

### Copy and Paste

```
yy   # yank (copy) current line
3yy  # yank 3 lines
yw   # yank word
y$   # yank to end of line
p    # paste after cursor/line
P    # paste before cursor/line
```

### Undo and Redo

```
u         # undo last change
Ctrl-r    # redo
.         # repeat last change (very useful!)
```

## Search

```
/pattern    # search forward
?pattern    # search backward
n           # next match
N           # previous match
*           # search for word under cursor (forward)
#           # search for word under cursor (backward)
```

## Visual Mode

```
v       # character-wise visual
V       # line-wise visual
Ctrl-v  # block visual (column selection)

# Once selected:
d   # delete selection
y   # yank selection
c   # change selection
>   # indent
<   # unindent
```

## Command Mode

```
:set number       # show line numbers
:set nonumber     # hide line numbers
:set hlsearch     # highlight search results
:nohl             # clear highlight
:set ignorecase   # case-insensitive search
:%s/old/new/g     # global search and replace in file
:%s/old/new/gc    # with confirmation
:10,20s/old/new/g # replace in lines 10-20
:sort             # sort all lines
:sort u           # sort and remove duplicates
```

## Tips

- `Esc Esc` — double-press Esc is always safe
- `:set paste` before pasting from clipboard to avoid autoindent issues
- Run `vimtutor` in the terminal for the official interactive tutorial (~30 min)

## Further Reading

- [Vim official documentation](https://vimdoc.sourceforge.net/htmldoc/usr_toc.html) — the complete Vim user manual covering every command in this lesson plus advanced features: macros, marks, folding, registers, and the command-line window.
- [Vim Adventures](https://vim-adventures.com/) — interactive browser game that teaches Vim navigation through puzzle levels; especially effective for internalizing `hjkl`, word motion, and the Normal/Insert mode switch.
- [Vim cheat sheet — rtorr](https://vim.rtorr.com/) — comprehensive single-page reference of all Normal, Visual, and Command mode shortcuts organized by category — bookmark this for the first few weeks.
- [Practical Vim by Drew Neil](https://pragprog.com/titles/dnvim2/practical-vim-second-edition/) — the most recommended book for moving beyond basics: the dot formula, text objects (`ciw`, `di"`), macros, and building editing habits that compose.
- [vimtutor](https://vimschool.netlify.app/introduction/vimtutor/) — the built-in interactive tutorial (run `vimtutor` in any terminal with Vim installed); covers the exact commands in this lesson in 25–30 minutes of hands-on practice.
