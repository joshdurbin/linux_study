# Exercise: Text Processing

## Setup — Create data files

Create `~/textlab/` and inside it create `access.log` with this content:

```
192.168.1.1 GET /index.html 200 1234
192.168.1.2 POST /api/login 401 89
192.168.1.1 GET /about.html 200 567
10.0.0.5 GET /index.html 200 1234
192.168.1.3 GET /api/data 500 0
10.0.0.5 POST /api/login 200 102
192.168.1.2 GET /index.html 200 1234
192.168.1.1 GET /favicon.ico 404 0
```

## Task 1 — awk field extraction

Using `awk`:
1. Print only the IP addresses (field 1) from `access.log` → save to `~/textlab/ips.txt`
2. Print only lines where the status code (field 4) is `200` → save to `~/textlab/ok_requests.txt`
3. Sum all the bytes (field 5) and print the total → save to `~/textlab/total_bytes.txt`

## Task 2 — sed substitution

1. Replace all occurrences of `GET` with `HTTP-GET` in `access.log` and save to `~/textlab/modified_log.txt` (do not modify the original)
2. Delete all lines containing `404` from `access.log` and save to `~/textlab/no404_log.txt`

## Task 3 — sort and uniq

1. Extract all IP addresses from `access.log` (field 1 with awk), sort them, and use `uniq -c` to count how many requests each IP made → save to `~/textlab/ip_counts.txt`
2. Sort `~/textlab/ip_counts.txt` in reverse numeric order (most requests first) → save to `~/textlab/ip_counts_sorted.txt`

## Task 4 — cut and pipeline

Using `/etc/passwd`:
1. Use `cut` to extract just usernames (field 1, colon-delimited) and system UIDs by extracting fields 1 and 3 → save to `~/textlab/user_uids.txt`
2. Sort the output numerically by the UID (second field) and save to `~/textlab/user_uids_sorted.txt`
