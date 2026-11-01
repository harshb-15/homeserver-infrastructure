# Recovering a one-sided WireGuard session after VPS reboot

## Context and impact

After a controlled VPS kernel update/reboot, SSH, Caddy and the WireGuard interface
started successfully on the VPS. However, every public application returned HTTP
502 because Caddy could not reach the homeserver peer.

## Symptom

- Public TLS and Caddy were available, but all upstreams returned 502.
- Caddy logged `no route to host` for tunnel destinations.
- The VPS WireGuard peer had no learned endpoint and zero tunnel traffic.
- The homeserver still displayed the pre-reboot peer/session and continued
  persistent keepalives.

## Investigation

I compared both WireGuard endpoints rather than restarting Caddy or applications:

- Interface/service state and routes on each host
- Latest handshake timestamps
- Learned peer endpoint on the VPS
- UDP firewall counters
- Caddy upstream errors
- Homeserver application health outside the tunnel

Containers and local application ports were healthy. Keepalive packets reached the
VPS firewall, but the rebooted peer did not yet share a usable cryptographic session
with the homeserver during the observation window.

## Root cause

The VPS reboot discarded ephemeral WireGuard session/endpoint state while the
homeserver retained its old session view. WireGuard may eventually renegotiate, but
the public path remained unavailable long enough to require a bounded recovery.
This was not a Caddy, DNS or container failure.

## Resolution

I restarted only the homeserver `wg-home` interface. Tailscale, LAN networking,
Docker and application containers were left running. A fresh two-sided handshake
appeared in approximately three seconds.

I then implemented a conservative systemd watchdog:

- Run every minute
- Probe the VPS specifically through `wg-home`
- Restart only when the probe fails **and** the handshake is at least 180 seconds old
- Enforce a 300-second cooldown
- Never start an intentionally disabled interface

## Verification

A controlled test stopped only the VPS WireGuard interface with an independent
VPS-side safety start. The real sandboxed watchdog detected the stale failure,
restarted only the home peer and logged recovery after a fresh handshake. A normal
healthy timer cycle made no change. Public routes and private-port denial passed.

## Lessons

- A service can be `active` while its peer state is unusable.
- Diagnose both tunnel endpoints and the application path before restarting apps.
- Self-healing must combine reachability, handshake age and cooldown to avoid
  masking transient packet loss or creating restart loops.
