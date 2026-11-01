#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 STACK [--check]" >&2
  exit 2
}

[[ $# -ge 1 && $# -le 2 ]] || usage
stack=$1
mode=${2:-apply}
[[ $stack =~ ^[a-z0-9][a-z0-9_-]*$ ]] || { echo 'Invalid stack name.' >&2; exit 2; }
[[ $mode == apply || $mode == --check ]] || usage

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
marker=$repo/inventory/deployment-enabled
if [[ ! -e $marker ]]; then
  echo 'Deployment is disabled during repository transition (missing inventory/deployment-enabled).' >&2
  exit 2
fi

mapfile -t matches < <(find "$repo/compose" -type f -path "*/$stack/compose.yml" -print)
[[ ${#matches[@]} -eq 1 ]] || {
  printf 'Expected exactly one Compose definition for %s; found %d.\n' "$stack" "${#matches[@]}" >&2
  exit 2
}
compose_file=${matches[0]}
runtime_env=${HOMESERVER_RUNTIME_ENV:-$HOME/.config/homeserver/runtime.env}
stack_env=$HOME/.config/homeserver/stacks/$stack.env
[[ -r $runtime_env ]] || { echo "Missing private runtime environment: $runtime_env" >&2; exit 2; }

env_args=(--env-file "$runtime_env")
[[ ! -r $stack_env ]] || env_args+=(--env-file "$stack_env")
compose=(docker compose --project-name "$stack" "${env_args[@]}" -f "$compose_file")

lock=${XDG_RUNTIME_DIR:-/tmp}/homeserver-deploy.lock
exec 9>"$lock"
flock -n 9 || { echo 'Another homeserver deployment is running.' >&2; exit 1; }

"${compose[@]}" config -q
mapfile -t images < <("${compose[@]}" config --images)
((${#images[@]} > 0)) || { echo 'Compose definition has no images.' >&2; exit 1; }
for image in "${images[@]}"; do
  [[ $image == *@sha256:* ]] || { echo "Refusing unpinned image: $image" >&2; exit 1; }
  docker image inspect "$image" >/dev/null
 done

printf 'Validated stack: %s\nDefinition: %s\nImages: %d immutable pins\n' "$stack" "$compose_file" "${#images[@]}"
if [[ $mode == --check ]]; then
  "${compose[@]}" config --services
  exit 0
fi

"${compose[@]}" up -d --pull never
"${compose[@]}" ps
printf 'Deployment completed for %s; perform service-specific health and boundary checks.\n' "$stack"
