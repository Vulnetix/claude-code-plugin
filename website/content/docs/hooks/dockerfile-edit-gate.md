---
title: Dockerfile Edit Gate
weight: 50
description: Background container scan after editing Dockerfile or Containerfile.
---

Background container scan after editing Dockerfile or Containerfile.

## Trigger

PostToolUse on Edit/Write

## Behavior

See [`hooks/dockerfile-edit-gate.sh`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/hooks/dockerfile-edit-gate.sh) and [`hooks/ts/openclaw/dockerfile-edit-gate/HOOK.md`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/hooks/ts/openclaw/dockerfile-edit-gate/HOOK.md). The hook reads `.vulnetix/capabilities.yaml` and skips work when the relevant binaries / repo signals are absent. Always exits 0; never blocks.

## See also

- [Capabilities YAML schema](/docs/data-structures/capabilities-yaml)
- [Hooks index](/docs/hooks/)
