#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
"$repo/scripts/status.sh"
if [[ -e $repo/inventory/deployment-enabled ]]; then
  "$repo/scripts/check-drift.sh"
else
  echo
  echo 'Drift check skipped: repository deployment is not enabled yet.'
fi
