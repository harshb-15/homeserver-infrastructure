# Enforcing access boundaries before Docker destination NAT

## Context and risk

The goal was to turn intended access policy into host-enforced boundaries without
breaking LAN, Tailscale or the four public upstreams.

## Symptom / exposure finding

Many application ports listened on all IPv4 and IPv6 host addresses. That did not
prove public-internet exposure—the router and upstream firewall still mattered—but
it also did not enforce the intended LAN/Tailscale/VPS boundaries on the host.

Docker-published ports complicate ordinary firewall assumptions because DNAT and
FORWARD processing can bypass an INPUT-only rule set.

## Investigation

I classified every service first:

- Public through the VPS: Jellyfin, Seerr, Home Assistant, Nextcloud
- LAN/Tailscale: administrative dashboards and SSH
- Tailscale only: Pi Web UI
- Container internal: databases, Valkey, machine learning and FlareSolverr

I then inspected listening sockets, Docker port mappings, interfaces, routes,
existing nftables/iptables chains, container networks and the current WireGuard
guard. Prowlarr already used FlareSolverr's container hostname, so its host port
could be removed without changing application behavior.

## Root cause

Service intent existed in documentation and router behavior, but the host lacked a
single NAT-aware policy enforcing it. Docker-published traffic could traverse
FORWARD after DNAT rather than an assumed INPUT-only path.

## Resolution

I installed a separate atomic nftables table with a prerouting filter priority
before Docker DNAT. It:

- Matches only local host destinations and a protected service-port set
- Allows the Ethernet LAN CIDR and Tailscale interface
- Keeps Pi Web UI Tailscale-only
- Allows the authenticated VPS peer only to four approved ports
- Blocks global IPv6 access to protected ports
- Preserves required container-to-host integrations

FlareSolverr's host port was removed entirely. The existing independent WireGuard
INPUT/FORWARD guard remained in place.

## Verification

Before installation, an isolated untrusted network namespace connected to SSH,
qBittorrent Web UI and Home Assistant over both IPv4 and global IPv6. Afterward,
the same technique was blocked across all tested protected ports.

Additional checks proved:

- Real LAN and mobile-data Tailscale access still worked
- All four public VPS paths remained healthy
- Ten private ports were blocked from the VPS tunnel
- Prowlarr reached FlareSolverr internally with no host listener
- Rules and service ordering survived controlled reboots

## Lessons

- Listening on `0.0.0.0` is evidence of interface exposure, not by itself proof of
  internet exposure; test each boundary accurately.
- Classify access before writing rules.
- Account for Docker's forwarding/NAT path explicitly.
- Own an isolated nftables table rather than flushing or replacing unrelated rules.
