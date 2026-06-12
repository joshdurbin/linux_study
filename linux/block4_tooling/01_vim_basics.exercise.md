# Exercise: Vim Basics

These exercises use the command line to verify vim operations by their results.

## Task 1 — Create and write a file

Use vim to create `~/vimlab/poem.txt` with exactly these 5 lines (use Insert mode):

```
Roses are red
Violets are blue
Linux is great
And so are you
The end
```

Save and quit. Verify with `cat ~/vimlab/poem.txt`.

## Task 2 — Edit with substitution

Open `~/vimlab/poem.txt` in vim and use the command-mode substitution to:
1. Replace `red` with `crimson` on line 1
2. Replace `blue` with `azure` on line 2

Use: `:%s/red/crimson/` and `:%s/blue/azure/`

Save and quit. The file should now contain `crimson` and `azure`.

## Task 3 — Script-based vim editing

Use vim in non-interactive mode to create `~/vimlab/config.ini` with specific content:

```bash
vim -es ~/vimlab/config.ini << 'EOF'
i[database]
host=localhost
port=5432
name=mydb
.
:wq
EOF
```

Alternatively, you can open vim normally and type the content. The file must exist and contain `[database]` and `host=localhost`.

## Task 4 — Verify vim is installed and check version

Run `vim --version` and save the first 5 lines to `~/vimlab/vim_version.txt`. Also, create `~/vimlab/done.txt` containing the word `complete` to indicate you finished the exercises.
