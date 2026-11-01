#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
if [[ ! -e $repo/inventory/deployment-enabled ]]; then
  echo 'Drift checking is disabled until cutover (missing inventory/deployment-enabled).' >&2
  exit 2
fi
runtime_env=${HOMESERVER_RUNTIME_ENV:-$HOME/.config/homeserver/runtime.env}
[[ -r $runtime_env ]] || { echo "Missing private runtime environment: $runtime_env" >&2; exit 2; }
umask 077
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
status=0
count=0

while IFS= read -r compose_file; do
  stack=$(basename "$(dirname "$compose_file")")
  stack_env=$HOME/.config/homeserver/stacks/$stack.env
  env_args=(--env-file "$runtime_env")
  [[ ! -r $stack_env ]] || env_args+=(--env-file "$stack_env")
  cfg=$tmp/$stack.json
  hashes=$tmp/$stack.hashes
  docker compose --project-name "$stack" "${env_args[@]}" -f "$compose_file" config --format json > "$cfg"
  docker compose --project-name "$stack" "${env_args[@]}" -f "$compose_file" config --hash='*' > "$hashes"
  if ! python3 - "$stack" "$compose_file" "$cfg" "$hashes" <<'PY'
import json,subprocess,sys
stack,compose_file,cfg_path,hash_path=sys.argv[1:]
cfg=json.load(open(cfg_path)); expected_hash=dict(line.strip().split(None,1) for line in open(hash_path) if line.strip()); drift=[]
for service,spec in cfg.get('services',{}).items():
    ref=spec.get('image'); name=spec.get('container_name')
    if not ref or not name: continue
    try:
        image_id=json.loads(subprocess.check_output(['docker','image','inspect',ref]))[0]['Id']
    except subprocess.CalledProcessError:
        drift.append(f'{service}: configured image unavailable'); continue
    try:
        live=json.loads(subprocess.check_output(['docker','inspect',name]))[0]
    except subprocess.CalledProcessError:
        drift.append(f'{service}: container {name} missing'); continue
    labels=live['Config'].get('Labels') or {}
    if image_id != live['Image']: drift.append(f'{service}: running image differs from configured digest')
    if labels.get('com.docker.compose.config-hash') != expected_hash.get(service): drift.append(f'{service}: running Compose configuration differs')
    if labels.get('com.docker.compose.project.config_files') != compose_file: drift.append(f'{service}: container not owned by repository definition')
    if labels.get('com.docker.compose.project') != stack: drift.append(f'{service}: project label differs')
if drift:
    print(stack+': DRIFT'); [print('  '+x) for x in drift]; raise SystemExit(1)
print(stack+': image/config/ownership match')
PY
  then status=1; fi
  count=$((count+1))
done < <(find "$repo/compose" -type f -name compose.yml -print | sort)

((count > 0)) || { echo 'No stack definitions found.' >&2; exit 2; }
exit "$status"
