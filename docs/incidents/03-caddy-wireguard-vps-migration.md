# Migrating public applications to Caddy over direct WireGuard

## Context and goal

Public applications originally depended on a connector-style tunnel. I wanted a
maintainable edge architecture with explicit routing, independently testable
firewalls, normal public certificates and no inbound home-router port forward.

## Symptom / design constraint

The existing path worked, but public delivery was coupled to connector lifecycle
and broad provider-specific behavior. There was no independently operated edge
where I could validate routing, firewall and application protocol behavior.

## Investigation

Before changing DNS, I mapped:

- Existing public hostnames and authentication boundaries
- Home application ports and Docker forwarding behavior
- VPS/provider firewall rules
- Home NAT constraints and dynamic egress address
- WebSocket, HTTP range, DAV and large-response requirements
- Rollback dependencies for each hostname

The resulting design uses Caddy on an ARM64 VPS. HTTPS terminates at the VPS and is
proxied over a point-to-point WireGuard tunnel. Each peer routes only the other
peer's tunnel `/32`; the tunnel is not a default route, exit node or LAN route.

## Root cause / design risk

Simply connecting the VPS to the homeserver would have exposed private dashboards
and SSH to a compromised edge host. I added a dedicated nftables guard with INPUT
and FORWARD hooks. The FORWARD rule matches Docker's original destination port even
after DNAT.

## Resolution

1. Installed WireGuard and root-only key material on both hosts.
2. Added narrow provider/OS firewall permits for HTTPS and WireGuard.
3. Deployed Caddy with loopback-only administration.
4. Enabled temporary test hostnames first.
5. Verified application-specific behavior before DNS cutover.
6. Migrated Jellyfin, Seerr, Home Assistant and Nextcloud individually.
7. Removed the old connector only after independent DNS resolvers and production
   paths passed.

## Verification

- Fresh WireGuard handshakes and direct VPS-to-home health requests
- Publicly trusted TLS without certificate bypass
- HTTP-to-HTTPS redirects
- Jellyfin range requests and authentication boundary
- Home Assistant WebSocket behavior
- Nextcloud status, DAV redirects and security headers
- Four approved upstream ports reachable from the VPS
- SSH and ten tested private application ports blocked through the tunnel

## Lessons

- A tunnel is transport, not authorization; enforce destinations independently.
- Test temporary hostnames before replacing production DNS.
- Validate protocol-specific behavior, not only an HTTP 200 health endpoint.
- Preserve exact rollback state until DNS, certificates and real application use
  are accepted.
