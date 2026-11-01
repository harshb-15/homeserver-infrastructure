#!/usr/bin/env bash
set -euo pipefail

section() { printf '\n== %s ==\n' "$1"; }
state() {
  local scope=$1 unit=$2 value
  if [[ $scope == user ]]; then
    value=$(systemctl --user is-active "$unit" 2>/dev/null || true)
  else
    value=$(systemctl is-active "$unit" 2>/dev/null || true)
  fi
  printf '%-34s %s\n' "$unit" "${value:-unknown}"
}

section Host
printf 'hostname: %s\n' "$(hostname)"
printf 'kernel:   %s\n' "$(uname -r)"
printf 'uptime:   %s\n' "$(uptime -p)"
printf 'failed systemd units: %s\n' "$(systemctl --failed --plain --no-legend 2>/dev/null | grep -c . || true)"

section Storage
df -h --output=target,size,used,avail,pcent / /mnt/storage 2>/dev/null | awk 'NR==1 || !seen[$1]++'

section Network
ip -br addr show 2>/dev/null | grep -E '^(en|eth|wl|tailscale0|wg-home)' || true
ip -4 route show default || true
for unit in systemd-networkd systemd-networkd-wait-online ssh.socket tailscaled wg-quick@wg-home wg-home-watchdog.timer homeserver-access-guard wg-home-firewall; do
  state system "$unit"
done

if command -v tailscale >/dev/null 2>&1; then
  tailscale status --json 2>/dev/null | python3 -c '
import json,sys
d=json.load(sys.stdin); s=d.get("Self", {})
print("tailscale backend:", d.get("BackendState", "unknown"))
print("tailscale online:", bool(s.get("Online")))
print("tailscale health messages:", len(d.get("Health") or []))
' || true
fi

section Docker
state system docker
if docker info >/dev/null 2>&1; then
  printf 'running containers: %s\n' "$(docker ps -q | wc -l)"
  printf 'unhealthy containers: %s\n' "$(docker ps --filter health=unhealthy -q | wc -l)"
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
  printf '\nCompose projects:\n'
  docker compose ls
else
  echo 'Docker unavailable.'
fi

section Pi
state user pi-web-ui.service

section Repository
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
if [[ -e $repo/inventory/deployment-enabled ]]; then
  echo 'repository deployment: enabled'
else
  echo 'repository deployment: DISABLED (transition safety latch)'
fi
if git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$repo" status --short --branch
fi
