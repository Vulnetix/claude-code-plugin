---
name: session-summary
description: 'SessionStart hook: read `.vulnetix/memory.yaml`, surface a one-line status when open critical/high findings exist, stay silent on clean repos. Use when seeding a session with prior security state — only when there is something to act on.'
event: agent:bootstrap
---

# Session-Summary hook

## Use when

- Session start, AND open critical/high findings exist in memory.yaml.


Runs the Vulnetix session summary hook to display a vulnerability status dashboard when the agent starts.

## Edge cases & gotchas

- Silent on clean repos (no open critical/high) — quiet-by-default.
- Open = `status: under_investigation | affected`; closed = `fixed | not_affected`.
- Counts use grep against memory.yaml — not perfect for nested status fields, but fast.
- Disabled if memory.yaml is missing.
- No cooldown — fires once at session start by definition.
