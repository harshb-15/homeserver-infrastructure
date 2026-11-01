# Compose definitions

Point 5 created one production-capable, public-safe definition per stack:

```text
compose/<group>/<stack>/compose.yml
```

Definitions use private runtime variables for host paths/topology and immutable
image digests. No live `.env`, application config, database or media is copied.
All 11 live projects have been recreated/verified from these repository paths.
