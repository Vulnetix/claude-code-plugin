---
name: iac-edit-gate
description: 'PostToolUse Edit/Write hook: detect writes to `*.tf` / `*.tofu` files; launch `vulnetix iac` in the background. Throttled per file. Use when surfacing IaC misconfigurations without blocking the edit.'
event: message:preprocessed
---

# Iac-Edit-Gate hook

## Use when

- An Edit/Write tool call targets `*.tf` or `*.tofu`.
- The same file has not been re-scanned this session.


PostToolUse hook on Edit/Write. Detects writes to `.tf` / `.tofu` files and launches `vulnetix iac` in the background.

## Edge cases & gotchas

- Background scan — results land in `/tmp/vulnetix-iac-*.json`; not visible inline.
- Per-file cooldown via `edit-gate:$FILE`.
- Single-file scan does not have cross-file context (provider blocks declared elsewhere may be unresolved).
- Hook only fires on `.tf` and `.tofu`; Pulumi / Crossplane / Bicep are not detected.
- Output cached per-file basename; same-named files in different dirs will overwrite.
