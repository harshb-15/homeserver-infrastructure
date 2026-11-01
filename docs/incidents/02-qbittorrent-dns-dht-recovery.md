# qBittorrent tracker and DHT recovery after Docker DNS failure

## Context and impact

qBittorrent remained online and retained its configuration/torrents, but downloads
stalled. Several items stayed in metadata download state and tracker communication
failed.

## Symptom

- Trackers reported `Host not found`.
- Three torrents remained in metadata download state.
- DHT node count was zero.
- Restarting the application process did not restore activity.

## Investigation

I checked application state before touching torrent data:

1. qBittorrent logs and tracker errors
2. DNS resolution inside the container
3. Docker's embedded resolver behavior
4. DHT node count and torrent states
5. Compose DNS declarations versus the running container

The container used Docker's embedded resolver, but tracker hostname lookups returned
`SERVFAIL`. Host resolution worked, so this was not a general ISP/router outage.
The zero-node DHT state was a consequence of the same inability to resolve/rejoin,
not evidence that torrent metadata or configuration needed deletion.

## Root cause

The running qBittorrent container had unusable Docker resolver state, equivalent to
the stale-DNS condition observed in Home Assistant. Trackers and bootstrap hosts
could not be resolved from inside the container.

## Resolution

I recreated only qBittorrent with the existing pinned image and current explicit
DNS configuration. Its bind-mounted configuration and torrent storage were left
unchanged.

```bash
docker compose up -d --pull never --force-recreate qbittorrent
```

## Verification

- DNS lookups succeeded inside the recreated container.
- Tracker errors cleared and all three torrents resumed.
- DHT recovered to more than 330 nodes.
- Transfer throughput reached approximately 12.7 MiB/s during observation.
- Existing torrent state and files remained intact.

## Lessons

- `Host not found`, zero DHT nodes and stalled metadata can share one network-layer
  cause; deleting torrents would have treated symptoms and destroyed useful state.
- Verify resolver behavior inside the exact network namespace that is failing.
- Preserve application data and recreate the container object when runtime settings
  differ from source configuration.
