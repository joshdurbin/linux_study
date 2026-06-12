# Exercise: apt Pinning

## Tasks

1. **Read current policy**: Run `apt-cache policy` and identify the priority of the default Ubuntu archive. Save the output to `~/practice/pin_policy_before.txt`.

2. **Write a preferences file**: Create `/etc/apt/preferences.d/study.pref` (via `sudo`) that pins `snapd` to priority `-1` (never install). Use the format from the lesson.

3. **Verify the pin**: Run `apt-cache policy snapd` after creating the file and confirm the priority is shown as `-1`. Save the output to `~/practice/pin_snapd_policy.txt`.

4. **Pin by version**: Write a second stanza to `~/practice/pin_example.pref` (not in /etc/apt/) that would pin `nginx` to version `1.24.*` at priority `1001`. You don't need to apply it — just write the correct format.

## Hints

- The preferences file must be owned by root: `sudo tee /etc/apt/preferences.d/study.pref`
- After writing the file, `apt-cache policy snapd` should show `Package pin: -1`
- If snapd isn't in the repos, `apt-cache policy snapd` may show "N: Unable to locate" — that's fine, the pin is still recorded
