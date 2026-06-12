# Exercise: apt Sources and Policy

## Tasks

1. **Explore policy**: Run `apt-cache policy curl` and write the output (installed version, candidate, and which repo it comes from) to `~/practice/apt_policy.txt`.

2. **Inspect dependencies**: Run `apt-cache depends curl` and `apt-cache rdepends --important curl`. Write the names of curl's `Depends` packages to `~/practice/apt_deps.txt`.

3. **Hold a package**: Put `nano` on hold with `apt-mark hold nano`, verify it appears in `apt-mark showhold`, then unhold it. Write the hold/unhold commands you used to `~/practice/apt_hold.txt`.

4. **Package metadata**: Run `apt-cache show jq` and save the `Version:`, `Depends:`, and `Description:` lines to `~/practice/apt_show.txt`.

## Hints

- `apt-cache policy` reads `/var/lib/apt/lists/` — run `apt-get update` first if lists are stale
- `apt-mark hold` requires root: `sudo apt-mark hold nano`
- Use `grep` to extract specific fields: `apt-cache show jq | grep -E "^(Version|Depends|Description)"`
