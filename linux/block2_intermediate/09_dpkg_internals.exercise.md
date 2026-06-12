# Exercise: dpkg Internals

## Tasks

1. **Package file list**: Run `dpkg -L curl` and save the output to `~/practice/dpkg_curl_files.txt`. Note the binary, lib, and man page locations.

2. **Reverse lookup**: Find which package owns `/usr/bin/find` using `dpkg -S`. Save the result to `~/practice/dpkg_find_owner.txt`.

3. **Package status**: Run `dpkg -l | grep "^rc"` to find packages that were removed but left config files behind. Save any results (or "none" if empty) to `~/practice/dpkg_rc_packages.txt`.

4. **Inspect the database**: Read `/var/lib/dpkg/info/bash.list` and save the first 10 lines to `~/practice/dpkg_bash_info.txt`. This is the list of files dpkg tracks for the bash package.

5. **Explore a package**: Run `dpkg -I /var/cache/apt/archives/*.deb 2>/dev/null | head -30` to inspect a cached `.deb` file, or run `apt-get download curl --print-uris` to see the URL. Save findings to `~/practice/dpkg_deb_info.txt`.

## Hints

- `dpkg -S` requires the exact path — try `which find` first
- `/var/lib/dpkg/info/` has one file per package per file type (`.list`, `.md5sums`, `.conffiles`)
- If the archives cache is empty, use `dpkg -L bash | head -10` instead for task 5
