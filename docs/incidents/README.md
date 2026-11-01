# Engineering case studies

These reports document actual diagnosis/migration work. Each distinguishes observed
evidence from assumptions and follows:

`Symptom -> Investigation -> Root cause -> Resolution -> Verification`.

| Case study | Engineering focus |
| --- | --- |
| [Home Assistant stale Docker DNS](01-home-assistant-docker-dns.md) | Runtime-versus-Compose state, layered DNS diagnosis, scoped recreation |
| [qBittorrent DNS and DHT recovery](02-qbittorrent-dns-dht-recovery.md) | Preserving torrent state while repairing container networking |
| [Caddy/WireGuard VPS migration](03-caddy-wireguard-vps-migration.md) | Edge architecture, narrow routing, staged DNS/TLS cutover |
| [WireGuard reboot recovery](04-wireguard-reboot-recovery.md) | Two-sided tunnel diagnosis and bounded self-healing |
| [Native Tailscale migration](05-native-tailscale-migration.md) | Removing Docker from the recovery path with protected rollback |
| [Docker pre-DNAT firewall](06-docker-prednat-firewall.md) | Accurate exposure classification and NAT-aware enforcement |
| [Source-of-truth cutover](07-source-of-truth-cutover.md) | Secrets/runtime separation, incremental migration and drift checks |

The reports intentionally omit credentials, live addresses, node identifiers and
personal application data. Metrics are included only where they were actually
observed during verification.
