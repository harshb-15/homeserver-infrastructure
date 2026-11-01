# Adding a service or feature

This checklist is mandatory for human and Pi-assisted changes. A new published
port is not protected merely because an application has authentication.

## 1. Define purpose and ownership

- What user problem does the service solve?
- Is it maintained and actively updated?
- What application data must survive container recreation?
- Does it require a database, cache, GPU, Bluetooth or privileged capability?
- What is the rollback/removal plan?

Prefer maintained upstream software over custom replacements unless custom code is
the project goal.

## 2. Assign an access class

Choose exactly one:

| Class | Expected reachability |
| --- | --- |
| `public_via_vps` | Caddy hostname -> WireGuard -> one approved homeserver port; also LAN/Tailscale |
| `private` | LAN and Tailscale only |
| `tailscale_only` | Tailscale only |
| `internal` | Docker network only; no host port |

Ask the user when the class is unclear. Never publish an administrative dashboard
through the VPS by default.

## 3. Design state and secrets

- Put persistent state under `${HOMESERVER_RUNTIME_ROOT}/STACK/...`.
- Put bulk files under `${STORAGE_ROOT}`.
- Add only placeholders to a tracked `.env.example`.
- Store live values under `~/.config/homeserver/stacks/STACK.env` with mode 0600.
- Do not copy application-generated config, databases, tokens or private keys to Git.
- Back up data before migrations or credential changes.

## 4. Add a Compose definition

Create:

```text
compose/<group>/<stack>/compose.yml
```

Requirements:

- Explicit project and container names
- Immutable `tag@sha256:digest` image references
- `restart: unless-stopped`
- Absolute bind paths through runtime variables
- No literal credentials
- No unnecessary privileges or host networking
- No host port for container-internal backends
- Existing external networks named explicitly

Do not use `latest` without a digest and do not automatically pull during deploy.

## 5. Update boundaries before publishing ports

For every host port:

1. Add it to the protected-port set in
   `infrastructure/firewall/homeserver-access-guard.nft.in`.
2. Add only the intended interface/source allow rule.
3. If public, add it separately to the WireGuard guard and a Caddy site.
4. Render and run `nft --check` before installing.
5. Confirm untrusted IPv4 and global IPv6 cannot reach it.

Docker's forwarding path can bypass ordinary INPUT-only firewall assumptions.

## 6. Update inventory and documentation

Update:

- `inventory/services.yaml`
- Relevant architecture diagram/data flow
- Operations and recovery notes
- README service tables when portfolio scope changes

Document integration work honestly; do not claim the upstream application as custom
software.

## 7. Validate before applying

```bash
./scripts/deploy-stack.sh STACK --check
./scripts/check-drift.sh
```

Also validate application-specific dependencies, storage ownership and available
resources. Review upstream release/migration notes.

## 8. Deploy one stack

```bash
./scripts/deploy-stack.sh STACK
```

Do not combine an unrelated host/network change with the first deployment.

## 9. Verify

At minimum:

- Container is running and healthy
- Exact configured image digest is running
- Persistent mounts point to intended locations
- DNS and required backend connections work
- Intended LAN/Tailscale/public route responds
- Disallowed interfaces and the VPS tunnel cannot reach private ports
- Logs contain no permission, migration or authentication failures
- Existing services remain healthy
- `./scripts/check-drift.sh` passes

For public services, test TLS, redirects, WebSockets/range requests where relevant,
and authentication boundaries without using production user credentials in scripts.

## 10. Accept or roll back

Only declare success after user/application checks pass. Otherwise restore the prior
digest/configuration and preserve state for diagnosis. Remove abandoned containers,
images or volumes only after confirming they are not shared and contain no required
data.
