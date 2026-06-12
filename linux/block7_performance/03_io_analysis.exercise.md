# I/O Analysis — Exercises

Complete these tasks. Record findings in `~/practice/io_analysis.txt`.

## Setup

```bash
mkdir -p ~/practice
```

## Task 1 — iostat extended stats

```bash
echo "=== iostat -xz 1 3 ===" >> ~/practice/io_analysis.txt
iostat -xz 1 3 >> ~/practice/io_analysis.txt
```

Review the output. Note:
- Which devices are active?
- What are the `await` values? (Under 1ms = NVMe, under 10ms = SSD, 5–20ms = HDD)
- Is `%util` near 100% on any device?

Add a one-line comment with your observation:

```bash
echo "# Observation: <your note about await and %util>" >> ~/practice/io_analysis.txt
```

## Task 2 — Read /proc/diskstats

```bash
echo "=== /proc/diskstats ===" >> ~/practice/io_analysis.txt
cat /proc/diskstats >> ~/practice/io_analysis.txt
```

Identify the first disk device line (e.g., `sda`, `vda`, or `nvme0n1`). Count the fields — there are 14 kernel-reported columns after the device name.

## Task 3 — Inspect block device layout

```bash
echo "=== lsblk ===" >> ~/practice/io_analysis.txt
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,ROTA >> ~/practice/io_analysis.txt
```

Is the root filesystem on a rotational disk (`ROTA=1`) or SSD (`ROTA=0`)?

## Task 4 — Measure write throughput with dd

```bash
echo "=== dd write throughput ===" >> ~/practice/io_analysis.txt
dd if=/dev/zero of=/tmp/dd_test bs=1M count=256 oflag=direct 2>&1 | tee -a ~/practice/io_analysis.txt
rm -f /tmp/dd_test
```

Note the reported MB/s. This is the raw sequential write speed of the storage.

## Task 5 — Summarize findings

Add a summary paragraph to your file:

```bash
cat >> ~/practice/io_analysis.txt << 'EOF'
=== Summary ===
# Fill in:
# - Storage type (SSD/HDD/NVMe/virtual):
# - Average await from iostat:
# - dd write throughput:
# - Any saturated devices?
EOF
```

## Verification

```bash
cat ~/practice/io_analysis.txt
```
