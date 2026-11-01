# Operations runbook

## Deployment state

This host completed Point 5 cutover: all 11 Compose projects are repository-owned
and the ignored local `inventory/deployment-enabled` safety marker exists. A fresh
clone remains deployment-disabled until an operator supplies private env files,
validates the host and intentionally creates that marker.

## Start an operating session

```bash
cd ~/homeserver-infrastructure
./scripts/status.sh
./scripts/check-drift.sh   # after deployment is enabled
```

Read `AGENTS.md` and `inventory/services.yaml`. Check the private publication
checklist referenced by the host-level Pi context when doing publication work.

## Future stack change

```bash
./scripts/deploy-stack.sh STACK --check
./scripts/deploy-stack.sh STACK
```

The deploy command loads private host variables from
`~/.config/homeserver/runtime.env` and an optional per-stack file under
`~/.config/homeserver/stacks/`. It validates Compose, rejects unpinned images,
and uses `--pull never`. It never imports runtime state into Git.

## Change discipline

1. Diagnose and identify affected components.
2. Back up database/configuration for high-impact work.
3. Edit repository source and documentation together.
4. Validate and inspect drift.
5. Deploy only the selected stack/component.
6. Verify health, logs, dependencies and access boundaries.
7. Record an incident/decision when the lesson is reusable.

## Recovery principles

- Native Tailscale and OpenSSH are the primary remote recovery path and do not
  depend on Docker.
- The VPS reaches only four approved application ports through WireGuard.
- A WireGuard watchdog can recover stale one-sided sessions.
- Images are immutable digest pins; retain the old digest during upgrades.
- Runtime databases/configuration stay outside Git and require separate backups.
- There is no storage redundancy; Git is not a data backup.

Repository Compose definitions preserve the existing runtime bind paths and project
names. Use `scripts/check-drift.sh` to compare image IDs, full Compose config hashes,
project labels and repository ownership before deployment.
