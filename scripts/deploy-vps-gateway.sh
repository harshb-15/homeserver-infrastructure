#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
marker=$repo/inventory/deployment-enabled
[[ -e $marker ]] || { echo 'Deployment is disabled.' >&2; exit 2; }
runtime_env=${HOMESERVER_RUNTIME_ENV:-$HOME/.config/homeserver/runtime.env}
[[ -r $runtime_env ]] || { echo "Missing $runtime_env" >&2; exit 2; }
set -a; . "$runtime_env"; set +a
: "${VPS_SSH_TARGET:?required}"
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
cp "$repo/infrastructure/caddy/Caddyfile" "$stage/Caddyfile"
cp -a "$repo/infrastructure/caddy/sites" "$stage/sites-enabled"
cp "$repo/infrastructure/caddy/10-homeserver-env.conf" "$stage/10-homeserver-env.conf"
{
  printf 'HOME_TUNNEL_IP=%s\n' "$HOME_TUNNEL_IP"
  printf 'VPS_PUBLIC_IP=%s\n' "$VPS_PUBLIC_IP"
  printf 'JELLYFIN_HOSTNAME=%s\n' "$JELLYFIN_HOSTNAME"
  printf 'SEERR_HOSTNAME=%s\n' "$SEERR_HOSTNAME"
  printf 'HOMEASSISTANT_HOSTNAME=%s\n' "$HOMEASSISTANT_HOSTNAME"
  printf 'NEXTCLOUD_HOSTNAME=%s\n' "$NEXTCLOUD_HOSTNAME"
} > "$stage/homeserver.env"
chmod 600 "$stage/homeserver.env"
remote=/tmp/homeserver-caddy-deploy.$$
ssh -o BatchMode=yes "$VPS_SSH_TARGET" "mkdir -m 700 '$remote'"
scp -q -r "$stage"/. "$VPS_SSH_TARGET:$remote/"
ssh -o BatchMode=yes "$VPS_SSH_TARGET" "sudo bash -s -- '$remote'" <<'REMOTE'
set -euo pipefail
stage=$1
set -a; . "$stage/homeserver.env"; set +a
caddy validate --config "$stage/Caddyfile"
stamp=$(date -u +%Y%m%dT%H%M%SZ)
backup=/var/backups/vps-gateway/repo-caddy-$stamp
install -d -m 700 "$backup"
cp -a /etc/caddy/Caddyfile /etc/caddy/sites-enabled /etc/systemd/system/caddy.service.d "$backup/" 2>/dev/null || true
install -o root -g root -m 644 "$stage/Caddyfile" /etc/caddy/Caddyfile
rm -rf /etc/caddy/sites-enabled
install -d -o root -g root -m 755 /etc/caddy/sites-enabled
find "$stage/sites-enabled" -type f -maxdepth 1 -name '*.caddy' -exec install -o root -g root -m 644 {} /etc/caddy/sites-enabled/ \;
install -o root -g root -m 600 "$stage/homeserver.env" /etc/caddy/homeserver.env
install -d -o root -g root -m 755 /etc/systemd/system/caddy.service.d
install -o root -g root -m 644 "$stage/10-homeserver-env.conf" /etc/systemd/system/caddy.service.d/10-homeserver-env.conf
systemctl daemon-reload
set -a; . /etc/caddy/homeserver.env; set +a
caddy validate --config /etc/caddy/Caddyfile
systemctl reload caddy
systemctl is-active caddy
rm -rf "$stage"
REMOTE
printf 'VPS Caddy deployment completed; verify all public routes.\n'
