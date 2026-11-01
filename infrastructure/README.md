# Host and gateway infrastructure

Public-safe templates cover:

- Caddy public HTTPS reverse proxy on the VPS
- WireGuard peer examples and tunnel access guards
- Pre-DNAT homeserver application access guard
- Ethernet-only Netplan template
- Native Tailscale firewall-mode drop-in
- WireGuard recovery watchdog and systemd units
- VPS SSH/Fail2ban policy

Files ending in `.in` contain `@VARIABLE@` placeholders rendered from the private
host runtime environment. WireGuard examples contain key placeholders only.
Tracked Caddy files use Caddy environment placeholders and contain no live address,
domain or credential. Point 5 validates rendered files against installed state;
future changes flow repository template -> reviewed render -> host installation.
