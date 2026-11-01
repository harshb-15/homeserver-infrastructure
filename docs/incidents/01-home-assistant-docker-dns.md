# Home Assistant integration failure caused by stale container DNS state

## Context and impact

Home Assistant itself was running, but a cloud-backed home automation integration
could no longer resolve its API hostname. Device control through that integration
failed while unrelated host networking continued to work.

## Symptom

- Integration requests failed with hostname/DNS errors.
- The host could resolve and reach the provider over HTTPS.
- Restarting Home Assistant did not fix the integration.

## Investigation

I compared resolution at four layers instead of treating this as an application-only
problem:

1. Host resolver and outbound HTTPS
2. Compose source configuration
3. Docker's effective container configuration
4. The container's generated `/etc/resolv.conf`

Compose declared explicit DNS servers, but the running container reported an empty
Docker DNS configuration. Its generated resolver file contained only a search line
and no usable nameserver. That contradicted the current Compose definition.

I also separated **restart** from **recreation**: `docker compose restart` restarts
the existing container object and does not apply changed DNS, mount, environment or
network settings.

## Root cause

The running Home Assistant container was stale relative to Compose. Its effective
Docker DNS state was malformed/empty, so application requests never reached the
integration provider. The historical event that originally produced the stale
container was not proven; the observable proximate cause was the runtime/Compose
configuration mismatch.

## Resolution

I recreated only Home Assistant from the existing pinned image and current Compose
configuration. Application data and configuration remained on the bind mount.

```bash
docker compose up -d --pull never --force-recreate homeassistant
```

## Verification

- Docker's effective DNS settings matched Compose after recreation.
- The container resolver contained usable nameservers.
- The provider hostname resolved inside the container.
- Provider HTTPS succeeded.
- Home Assistant returned HTTP 200 and the integration recovered.
- No other stack was recreated.

## Lessons

- Inspect effective container state, not just YAML.
- A restart is not a configuration reconciliation operation.
- Test DNS at host, Docker and application layers before changing application data.
- Recreate the smallest affected unit and verify the external dependency directly.
