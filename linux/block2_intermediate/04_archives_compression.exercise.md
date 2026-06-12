# Exercise: Archives and Compression

## Setup

Create `~/archivelab/source/` and put some files in it:

```bash
mkdir -p ~/archivelab/source
echo "config value one" > ~/archivelab/source/config.txt
echo "data row 1" > ~/archivelab/source/data.csv
echo "data row 2" >> ~/archivelab/source/data.csv
mkdir -p ~/archivelab/source/subdir
echo "nested file" > ~/archivelab/source/subdir/nested.txt
```

## Task 1 — Create tar archives

1. Create a plain (uncompressed) tar archive of `~/archivelab/source/` at `~/archivelab/source.tar`
2. Create a gzip-compressed archive at `~/archivelab/source.tar.gz`
3. Use `tar -tf` to list the contents of the gzip archive and save to `~/archivelab/archive_contents.txt`

## Task 2 — Extract

1. Extract `source.tar.gz` into `~/archivelab/extracted/` (create it first, use `-C`)
2. Verify the extracted files are present: `~/archivelab/extracted/` should contain `config.txt`, `data.csv`, and `subdir/nested.txt`

## Task 3 — gzip a file directly

1. Copy `~/archivelab/source/data.csv` to `~/archivelab/data_copy.csv`
2. Compress it with `gzip` (this will create `data_copy.csv.gz` and remove the original)
3. Use `zcat ~/archivelab/data_copy.csv.gz` to verify the content and save to `~/archivelab/gzip_verify.txt`

## Task 4 — zip archive

Create a zip archive `~/archivelab/source.zip` containing all files in `~/archivelab/source/` (recursive). Then use `unzip -l ~/archivelab/source.zip` to list the contents and save to `~/archivelab/zip_listing.txt`.
