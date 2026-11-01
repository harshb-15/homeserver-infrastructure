# Security documentation

This directory will describe the public-safe security model:

- LAN/Tailscale/VPS/internal access classes
- Pre-DNAT Docker port filtering
- WireGuard peer allow-listing
- Native Tailscale recovery path
- SSH and VPS hardening
- Secret/runtime-state boundaries
- Digest-pinned image update process
- Pi approval controls and their limitations

Approval prompts are operational guardrails, not an operating-system sandbox.
