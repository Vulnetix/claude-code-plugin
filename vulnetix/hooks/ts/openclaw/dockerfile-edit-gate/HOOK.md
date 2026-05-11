---
name: dockerfile-edit-gate
description: 'PostToolUse Edit/Write hook: detect writes to Dockerfile / Containerfile / *.dockerfile; launch `vulnetix containers` in the background. Results land in `/tmp/vulnetix-dockerfile-*.json`. Throttled per file. Use when surfacing container hygiene issues without blocking the edit.'
event: message:preprocessed
---

# Dockerfile-Edit-Gate hook

## Use when

- An Edit/Write tool call targets a Dockerfile / Containerfile / *.dockerfile.
- The same file has not been re-scanned this session.


PostToolUse hook on Edit/Write. Detects writes to Dockerfile/Containerfile/*.dockerfile and launches `vulnetix containers` in the background; results land in /tmp for `/vulnetix:container-scan` to consume.

## Edge cases & gotchas

- Background scan — results are NOT visible immediately. Use `/vulnetix:container-scan` to fetch.
- Per-file cooldown via `edit-gate:$FILE` key.
- Multi-stage Dockerfiles are scanned as a whole; per-stage findings are not isolated.
- Hook ignores files outside the working tree.
- Output cached to `/tmp/vulnetix-dockerfile-${BN}.json` — overwritten on each fire.
