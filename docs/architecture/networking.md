# Networking and trust boundaries

## Request paths

```mermaid
flowchart TB
    subgraph public[Untrusted public network]
        internet[Internet clients]
    end

    subgraph vps[VPS]
        ingress[OS + provider firewall]
        tls[Caddy :443]
        wg1[wg-home peer]
        ingress --> tls --> wg1
    end

    subgraph server[Homeserver]
        wg2[wg-home peer]
        wg_guard[wg_home_guard<br/>INPUT + FORWARD hooks]
        access_guard[homeserver_access_guard<br/>prerouting before Docker DNAT]
        hostapps[Host listeners<br/>SSH / Home Assistant / Pi]
        dockerports[Docker-published ports]
        wg2 --> wg_guard --> access_guard
        access_guard --> hostapps
        access_guard --> dockerports
    end

    subgraph tailnet[Private tailnet]
        admin[Admin devices]
        ts0[tailscale0]
        admin --> ts0
    end

    internet -->|TCP 80/443| ingress
    wg1 <-->|UDP tunnel| wg2
    ts0 --> access_guard

    classDef untrusted fill:#fee2e2,stroke:#dc2626,color:#111827
    classDef guarded fill:#ffedd5,stroke:#ea580c,color:#111827
    classDef private fill:#dcfce7,stroke:#16a34a,color:#111827
    class internet untrusted
    class ingress,tls,wg1,wg2,wg_guard,access_guard guarded
    class admin,ts0,hostapps,dockerports private
```

## Access matrix

| Source | Permitted destinations | Explicitly excluded |
| --- | --- | --- |
| Public internet | VPS Caddy on HTTP/HTTPS | Direct homeserver ports |
| VPS WireGuard peer | TCP 5055, 8088, 8096, 8123 | SSH and private dashboards |
| Home LAN | Application ports and SSH | FlareSolverr/database direct access |
| Tailscale | Private apps, SSH, public apps | Pi still requires its application token |
| Docker networks | Required service-to-service APIs | No implied public exposure |

## Why the guard runs before Docker DNAT

Docker installs forwarding/NAT rules for published ports. An INPUT-only policy can
therefore produce a false sense of protection. `homeserver_access_guard` attaches
a prerouting filter before Docker destination NAT, matches original host service
ports, and permits only classified interfaces/sources.

The separate `wg_home_guard` table applies both INPUT and FORWARD hooks so the VPS
peer cannot use the tunnel to reach the LAN or unrelated containers.

## Addressing policy

The public repository uses placeholders. Live values are supplied from root/user
private environment files:

- Ethernet interface and router-reserved DHCP address
- LAN CIDR
- WireGuard peer `/32` addresses
- VPS public endpoint and DNS hostnames

Wi-Fi is disabled and is not accepted as a trusted LAN ingress interface.
