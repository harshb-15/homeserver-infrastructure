# Pre-commit publication scan

Date: 2026-11-01

## Scope

The complete repository working tree was scanned before the first `git add` or
commit. At the initial scan it contained 72 text files, no symlinks, no binary or
large files, no staged entries, no commits, no remotes and no unreachable Git
objects. The ignored host-local deployment marker was the only ignored file.

## Independent scanners

| Scanner | Version | Mode | Result |
| --- | --- | --- | --- |
| Gitleaks | 8.30.1 | Filesystem/directory, default rules, 100% redaction | 0 findings |
| TruffleHog | 3.99.7 | Filesystem, offline/no verification, archives skipped | 0 findings |

Both binaries were downloaded from their official GitHub releases into a temporary
directory and verified against the publishers' SHA-256 checksum files. TruffleHog
verification was deliberately disabled so no candidate value would be sent to a
third-party API.

## Manual review

- Enumerated every candidate and ignored path.
- Confirmed no symlinks, binary files, files over 1 MiB or world-writable files.
- Searched for private-key headers and common provider/token formats.
- Checked sensitive-style environment assignments for non-placeholder values.
- Reviewed every IPv4 and MAC literal; only loopback, public DNS, documentation
  ranges and explicit examples are present.
- Checked for live usernames, home paths, domains, public/private addresses,
  tailnet identifiers and previously used credentials.
- Confirmed `.env`, private state, databases and deployment marker are excluded.
- Confirmed the live runtime tree remains a separate non-Git directory.

## Git-history verification

After the clean working-tree scan, the initial commit was created with 72 tracked
files; the host-local deployment marker remained ignored. Before any remote was
configured:

- Gitleaks Git-history mode: 0 findings
- TruffleHog Git source mode with verification disabled: 0 findings
- `git fsck --full`: passed
- Working tree: clean
- Remotes: none

The report update was amended into the initial commit and both Git-history scanners
were run once more against the final commit before repository creation.

This report records scanner scope/results, not an assertion that automated scanning
can prove the absence of every possible secret. Manual review and credential
rotation remain required if any value is ever accidentally committed.
