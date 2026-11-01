# Container network topology

```mermaid
flowchart LR
    subgraph mediaNet[External Docker network: homeserver]
        jf[Jellyfin]
        seerr[Seerr]
        sonarr[Sonarr]
        radarr[Radarr]
        prowlarr[Prowlarr]
        bazarr[Bazarr]
        qbit[qBittorrent]
        flare[FlareSolverr]

        seerr --> sonarr
        seerr --> radarr
        seerr --> jf
        sonarr --> prowlarr
        radarr --> prowlarr
        prowlarr --> flare
        sonarr --> qbit
        radarr --> qbit
        bazarr --> sonarr
        bazarr --> radarr
    end

    subgraph immichNet[Project network: immich_default]
        iserver[Immich server]
        idb[(PostgreSQL)]
        valkey[(Valkey)]
        ml[Machine learning]
        iserver --> idb
        iserver --> valkey
        iserver --> ml
    end

    subgraph nextcloudNet[Project network: nextcloud_default]
        nc[Nextcloud Apache]
        mariadb[(MariaDB)]
        nc --> mariadb
    end

    subgraph hostNet[Host network]
        ha[Home Assistant]
    end

    edge[Host-published ports]
    edge --> jf
    edge --> seerr
    edge --> sonarr
    edge --> radarr
    edge --> prowlarr
    edge --> bazarr
    edge --> qbit
    edge --> iserver
    edge --> nc
    edge --> ha

    classDef internal fill:#dbeafe,stroke:#2563eb,color:#111827
    classDef app fill:#dcfce7,stroke:#16a34a,color:#111827
    classDef boundary fill:#ffedd5,stroke:#ea580c,color:#111827
    class idb,valkey,ml,mariadb,flare internal
    class jf,seerr,sonarr,radarr,prowlarr,bazarr,qbit,iserver,nc,ha app
    class edge boundary
```

## Isolation choices

- Media services use one explicit external network because they intentionally call
  each other's APIs by container name.
- Immich and Nextcloud keep databases on project-local networks.
- FlareSolverr is reachable by Prowlarr but has no host-published port.
- Home Assistant uses host networking for LAN discovery and Bluetooth integrations;
  host firewall rules protect its HTTP listener.
- Container-network membership is convenience/connectivity, not a strong sandbox
  against a compromised container.
