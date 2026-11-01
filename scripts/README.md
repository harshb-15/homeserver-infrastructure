# Operations scripts

- `status.sh`: redacted host/service/container snapshot; safe before deployment.
- `preflight.sh`: status plus drift check when repository deployment is enabled.
- `check-drift.sh`: compares configured digest pins to running container images.
- `deploy-stack.sh STACK [--check]`: validates and deploys one enabled stack with
  private host/per-stack env files and `--pull never`.

The ignored `inventory/deployment-enabled` marker prevents accidental deployment
from a fresh clone. This host created it only after Point 5 completed and verified
all stack and infrastructure cutovers.
