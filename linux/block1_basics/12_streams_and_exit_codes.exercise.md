# Exercise: Exit Codes, Streams, and xargs

## Setup

```bash
mkdir -p ~/practice/streams
```

## Task 1: Observe Exit Codes

Run each command and check `$?`:

```bash
ls /etc > /dev/null
echo "ls /etc exit: $?"

ls /nonexistent 2>/dev/null
echo "ls /nonexistent exit: $?"

true;  echo "true exit: $?"
false; echo "false exit: $?"
```

Note the pattern: 0 = success, non-zero = failure.

## Task 2: Separate stdout and stderr

```bash
find /etc -name "*.conf" \
    1>~/practice/streams/found.txt \
    2>~/practice/streams/errors.txt

echo "Lines of output: $(wc -l < ~/practice/streams/found.txt)"
echo "Lines of errors: $(wc -l < ~/practice/streams/errors.txt)"
```

The `.conf` paths go to `found.txt`; permission-denied messages go to `errors.txt`.

## Task 3: Write a Script that Uses stderr

```bash
cat > ~/practice/streams/warn.sh << 'EOF'
#!/bin/bash
echo "Normal output to stdout"
echo "Warning: something went wrong" >&2
exit 0
EOF
chmod +x ~/practice/streams/warn.sh
```

Run it and capture each stream separately:

```bash
~/practice/streams/warn.sh \
    1>~/practice/streams/stdout.txt \
    2>~/practice/streams/stderr.txt

echo "stdout: $(cat ~/practice/streams/stdout.txt)"
echo "stderr: $(cat ~/practice/streams/stderr.txt)"
```

## Task 4: xargs Basic Usage

```bash
# Create some test files
touch ~/practice/streams/a.txt ~/practice/streams/b.txt ~/practice/streams/c.txt

# Count lines in all .txt files using xargs
ls ~/practice/streams/*.txt | xargs wc -l

# Copy each .txt file to a .bak using -I{}
ls ~/practice/streams/*.txt | xargs -I{} cp {} {}.bak
ls ~/practice/streams/*.bak
```

## Task 5: xargs with Spaces in Filenames

```bash
touch ~/practice/streams/"report 2024.txt"

# Default xargs splits on whitespace — this breaks
find ~/practice/streams -name "*.txt" | xargs ls -la 2>&1 | grep -c "No such"

# Null-delimited is safe
find ~/practice/streams -name "*.txt" -print0 | xargs -0 ls -la
```

## Task 6: xargs -n and -P

```bash
# -n: two arguments per invocation
echo "a b c d e f" | xargs -n 2 echo

# -P: two parallel echo jobs (order may vary)
echo "one
two
three" | xargs -P 2 -I{} echo "processing: {}"
```

## Expected Outcome

- `~/practice/streams/found.txt` — .conf paths from find
- `~/practice/streams/errors.txt` — permission-denied lines
- `~/practice/streams/warn.sh` — script with `>&2` redirect
- `~/practice/streams/*.bak` — copies of the .txt files
