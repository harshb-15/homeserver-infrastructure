# Moving the recovery path from Docker to native Tailscale

## Context and goal

Tailscale provided remote SSH and Pi Web UI access but ran in a privileged,
host-networked Docker container. If Docker failed to start, the tool needed to
repair Docker would also be unavailable. I migrated the same node identity to the
official host systemd service.

## Symptom

The native package post-install unexpectedly started `tailscaled` while the
container still owned the shared host network namespace. The new unconfigured
daemon failed, and its cleanup removed Tailscale addresses installed by the still-
running container. Remote endpoints briefly became unreachable.

## Investigation

I checked process ownership, systemd state, the container's backend state and the
actual `tailscale0` addresses. The container believed it was online, but the host
interface had lost its assigned tailnet addresses. That separated control-plane
state from real network state.

## Root cause

The package post-install started a second daemon in the same host network namespace.
That unconfigured process failed and ran its cleanup path, removing shared interface
state that the container still expected to own.

## Resolution

- Disabled and stopped the native unit
- Waited for native cleanup to finish
- Restarted the original container
- Confirmed the original identity, addresses, SSH and Pi Web UI returned

No state migration proceeded until the old path was healthy again.

### Controlled cutover

1. Created an integrity-tested private state/config backup.
2. Installed the official native package without relying on the package start.
3. Armed an independent timed rollback that would restart the container.
4. Stopped the container and copied quiesced identity state to the native location.
5. Started native Tailscale with the existing nftables backend.
6. Preserved the explicit node hostname.
7. Verified peer connectivity and management endpoints.
8. Canceled rollback, then removed the old container, image, Compose file and
   duplicate private state.

## Verification

- Backend online and healthy with the original IPv4/IPv6 identity
- Direct ping to another online tailnet device
- OpenSSH, Pi Web UI and a private application reachable through Tailscale
- Native service enabled with `Restart=on-failure`
- Controlled reboot proved startup without physical login and before Docker
- No failed systemd units; public applications unaffected

## Lessons

- Recovery-plane dependencies should be simpler than the systems they repair.
- Package post-install behavior must be treated as an active migration step.
- Verify the host interface, not only daemon-reported control state.
- Keep an independent rollback path armed until real peer traffic succeeds.
