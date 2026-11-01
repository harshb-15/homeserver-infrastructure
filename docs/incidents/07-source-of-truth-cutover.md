# Converting a live mutable deployment into a public-safe source of truth

## Context and goal

The homeserver began as separate working Compose directories mixed with runtime
configuration and application state. Publishing that tree directly would risk
credentials, databases, private topology and noisy generated files. Maintaining a
second sanitized copy manually would inevitably drift.

## Symptom / design limitation

A Compose change made in the live tree would not update a separate portfolio copy,
and a change made only in that copy would not affect production. There was no safe,
one-directional deployment workflow or exact drift proof.

## Investigation

I separated artifacts into two classes:

**Version-controlled declarations**

- Compose definitions and immutable image digests
- Firewall, network, Caddy and systemd templates
- Service inventory, operations scripts and documentation

**Private/runtime state**

- Environment files and keys
- Application config/databases/sessions
- Media, uploads, logs and caches

The new repository uses private host variables for bind paths/topology and private
per-stack env files for credentials. An ignored local deployment marker prevents a
fresh clone from applying configuration accidentally.

## Root cause

Declarative configuration, private values and mutable runtime state had grown in the
same directory hierarchy. A second manually sanitized tree would reproduce the
same ambiguity rather than establish authority.

## Resolution

1. Created a new repository with zero history/remotes and strict exclusions.
2. Added durable Pi/human operating instructions and machine-readable inventory.
3. Exported 11 public-safe Compose stacks with 15 digest-pinned images.
4. Rendered/validated firewall, Netplan, WireGuard, systemd and Caddy templates.
5. Took a fresh private pre-cutover definition backup.
6. Used Compose dry-runs to identify every recreation.
7. Migrated one stack at a time, preserving project/container names and bind paths.
8. Verified health, dependencies, mounts, databases, GPU and network boundaries.
9. Deployed matching host templates and VPS Caddy files with rollback backups.
10. Removed duplicate live Compose/env files and enabled repository deployment.
11. Changed Pi Web UI's workspace to the repository.

## Drift detection

`check-drift.sh` compares, without printing environment values:

- Configured image IDs versus running image IDs
- Full Compose service configuration hashes
- Compose project labels
- Repository config-file ownership labels

Installed host/VPS files were also hash/semantic-checked against rendered templates.

## Verification

- All 15 running containers identify repository Compose paths
- Eleven projects pass image/config/ownership drift checks
- No duplicate Compose or private env file remains in the runtime tree
- Private env files are mode 0600 outside Git
- Host infrastructure matches rendered/static repository files
- VPS Caddy/drop-in/site hashes match repository files
- Public HTTPS, private-port denial, DB logins, GPU, media mounts and app health pass
- Repository still has no commit or remote pending full secret/history review

## Lessons

- Avoid bidirectional synchronization; use repository-to-runtime deployment only.
- A sanitized template can also be production-capable when host-specific values are
  externalized instead of maintaining a second edited copy.
- Migrate incrementally and prove ownership through runtime labels, not assumptions.
- Delay the first commit until the entire tree has been scanned and reviewed.
