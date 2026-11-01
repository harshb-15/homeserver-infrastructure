# System overview

This diagram separates public delivery, private administration and runtime state.
Only four applications cross the VPS-to-home boundary.

```mermaid
flowchart LR
    viewer[Public user]
    admin[Administrator<br/>phone or laptop]
    dns[Authoritative DNS<br/>DNS only]

    subgraph edge[Public VPS trust zone]
        caddy[Caddy<br/>TLS + reverse proxy]
        vpsfw[VPS firewall<br/>80, 443, WireGuard, SSH]
        fail2ban[Fail2ban +<br/>key-only SSH]
        caddy --- fail2ban
        vpsfw --> caddy
    end

    subgraph tunnel[Encrypted point-to-point transport]
        wg[WireGuard<br/>narrow peer routes]
    end

    subgraph home[Homeserver trust zone]
        guard[WireGuard allow-list<br/>four app ports only]
        prednat[Pre-DNAT nftables<br/>service access guard]
        docker[Docker Engine<br/>11 Compose projects]
        tailscale[Native Tailscale<br/>management plane]
        ssh[OpenSSH]
        pi[Pi Web UI<br/>token + approvals]

        subgraph publicapps[Approved public upstreams]
            jellyfin[Jellyfin]
            seerr[Seerr]
            ha[Home Assistant]
            nextcloud[Nextcloud]
        end

        subgraph privateapps[Private applications]
            automation[Sonarr / Radarr<br/>Prowlarr / Bazarr]
            qbit[qBittorrent]
            immich[Immich]
        end

        subgraph internal[Container-internal backends]
            databases[MariaDB / PostgreSQL]
            cache[Valkey / ML / FlareSolverr]
        end

        guard --> prednat --> docker
        docker --> publicapps
        docker --> privateapps
        docker --> internal
        tailscale --> ssh
        tailscale --> pi
        tailscale --> privateapps
    end

    viewer --> dns --> vpsfw
    caddy --> wg --> guard
    admin -->|Tailscale| tailscale

    classDef public fill:#fee2e2,stroke:#dc2626,color:#111827
    classDef edge fill:#ffedd5,stroke:#ea580c,color:#111827
    classDef encrypted fill:#dbeafe,stroke:#2563eb,color:#111827
    classDef private fill:#dcfce7,stroke:#16a34a,color:#111827
    class viewer,dns public
    class caddy,vpsfw,fail2ban edge
    class wg encrypted
    class guard,prednat,docker,tailscale,ssh,pi,jellyfin,seerr,ha,nextcloud,automation,qbit,immich,databases,cache private
```

## Design properties

- Public TLS ends on the VPS; the upstream HTTP hop is protected by WireGuard.
- WireGuard routes only peer addresses, not the home LAN or default route.
- The homeserver peer firewall permits only Jellyfin, Seerr, Home Assistant and
  Nextcloud from the VPS.
- Native Tailscale remains available even when Docker is broken.
- Databases and support backends have no host-published management port.
