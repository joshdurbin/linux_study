#!/bin/bash
PASS=0
FAIL=0

check() {
  local desc="$1"
  local result="$2"
  if [[ "$result" == "ok" ]]; then
    echo "PASS: $desc"
    ((PASS++))
  else
    echo "FAIL: $desc — $result"
    ((FAIL++))
  fi
}

[[ -d ~/archivelab ]] && r="ok" || r="~/archivelab not found"
check "~/archivelab exists" "$r"

# Task 1: source.tar
[[ -f ~/archivelab/source.tar ]] && r="ok" || r="source.tar not found"
check "source.tar exists" "$r"

if [[ -f ~/archivelab/source.tar ]]; then
  tar -tf ~/archivelab/source.tar > /dev/null 2>&1 && r="ok" || r="source.tar is not a valid tar archive"
  check "source.tar is a valid tar archive" "$r"
fi

# source.tar.gz
[[ -f ~/archivelab/source.tar.gz ]] && r="ok" || r="source.tar.gz not found"
check "source.tar.gz exists" "$r"

if [[ -f ~/archivelab/source.tar.gz ]]; then
  tar -tzf ~/archivelab/source.tar.gz > /dev/null 2>&1 && r="ok" || r="source.tar.gz is not a valid gzip archive"
  check "source.tar.gz is a valid gzip archive" "$r"
fi

# archive_contents.txt
[[ -f ~/archivelab/archive_contents.txt ]] && r="ok" || r="archive_contents.txt not found"
check "archive_contents.txt exists" "$r"

if [[ -f ~/archivelab/archive_contents.txt ]]; then
  grep -q "config\|data\|nested" ~/archivelab/archive_contents.txt && r="ok" || r="archive_contents.txt doesn't list expected files"
  check "archive_contents.txt lists expected files" "$r"
fi

# Task 2: extraction
[[ -d ~/archivelab/extracted ]] && r="ok" || r="~/archivelab/extracted not found"
check "extracted/ directory exists" "$r"

# Check for extracted files (path may include 'source' prefix)
find ~/archivelab/extracted -name "config.txt" | grep -q "config.txt" && r="ok" || r="config.txt not found in extracted/"
check "config.txt was extracted" "$r"

find ~/archivelab/extracted -name "data.csv" | grep -q "data.csv" && r="ok" || r="data.csv not found in extracted/"
check "data.csv was extracted" "$r"

find ~/archivelab/extracted -name "nested.txt" | grep -q "nested.txt" && r="ok" || r="nested.txt not found in extracted/"
check "nested.txt was extracted" "$r"

# Task 3: gzip
[[ -f ~/archivelab/data_copy.csv.gz ]] && r="ok" || r="data_copy.csv.gz not found (did you run gzip data_copy.csv?)"
check "data_copy.csv.gz exists" "$r"

[[ ! -f ~/archivelab/data_copy.csv ]] && r="ok" || r="data_copy.csv still exists (gzip should have removed it)"
check "data_copy.csv removed by gzip" "$r"

[[ -f ~/archivelab/gzip_verify.txt ]] && r="ok" || r="gzip_verify.txt not found"
check "gzip_verify.txt exists" "$r"

if [[ -f ~/archivelab/gzip_verify.txt ]]; then
  grep -q "data row" ~/archivelab/gzip_verify.txt && r="ok" || r="gzip_verify.txt doesn't contain expected csv content"
  check "gzip_verify.txt has csv content" "$r"
fi

# Task 4: zip
[[ -f ~/archivelab/source.zip ]] && r="ok" || r="source.zip not found"
check "source.zip exists" "$r"

[[ -f ~/archivelab/zip_listing.txt ]] && r="ok" || r="zip_listing.txt not found"
check "zip_listing.txt exists" "$r"

if [[ -f ~/archivelab/zip_listing.txt ]]; then
  grep -q "config\|data\|nested" ~/archivelab/zip_listing.txt && r="ok" || r="zip_listing.txt doesn't list expected files"
  check "zip_listing.txt contains expected files" "$r"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
