# Media request and processing pipeline

```mermaid
flowchart LR
    user[User] -->|request| seerr[Seerr]
    seerr -->|TV| sonarr[Sonarr]
    seerr -->|movies| radarr[Radarr]
    sonarr -->|search| prowlarr[Prowlarr]
    radarr -->|search| prowlarr
    prowlarr -->|browser challenge when required| flare[FlareSolverr]
    prowlarr --> indexers[Indexer endpoints]
    sonarr -->|download job| qbit[qBittorrent]
    radarr -->|download job| qbit
    qbit -->|incomplete/complete data| torrents[(Torrent storage)]
    torrents -->|import + rename| sonarr
    torrents -->|import + rename| radarr
    sonarr --> tv[(TV library)]
    radarr --> movies[(Movie library)]
    bazarr[Bazarr] -->|subtitle requests| sonarr
    bazarr -->|subtitle requests| radarr
    bazarr --> tv
    bazarr --> movies
    tv --> jellyfin[Jellyfin]
    movies --> jellyfin
    jellyfin -->|GPU transcode or direct play| viewer[Viewer]

    classDef request fill:#f3e8ff,stroke:#9333ea,color:#111827
    classDef automation fill:#dbeafe,stroke:#2563eb,color:#111827
    classDef storage fill:#fef3c7,stroke:#d97706,color:#111827
    classDef playback fill:#dcfce7,stroke:#16a34a,color:#111827
    class user,seerr request
    class sonarr,radarr,prowlarr,flare,qbit,bazarr,indexers automation
    class torrents,tv,movies storage
    class jellyfin,viewer playback
```

## Operational properties

- `/data` mappings are consistent across Sonarr, Radarr and Bazarr so imported
  paths refer to the same underlying storage.
- qBittorrent peer traffic is separate from its private Web UI.
- FlareSolverr is a backend API, not an administrator-facing service.
- Jellyfin reads final libraries and can use NVIDIA hardware acceleration.
- Request automation cannot replace storage monitoring, import verification or
  application-level authentication.
