---
title: IaC Edit Gate
weight: 50
description: Background IaC scan after editing *.tf or *.tofu files.
---

Background IaC scan after editing *.tf or *.tofu files.

## Trigger

PostToolUse on Edit/Write

## Behavior

See [`hooks/iac-edit-gate.sh`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/hooks/iac-edit-gate.sh) and [`hooks/ts/openclaw/iac-edit-gate/HOOK.md`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/hooks/ts/openclaw/iac-edit-gate/HOOK.md). The hook reads `.vulnetix/capabilities.yaml` and skips work when the relevant binaries / repo signals are absent. Always exits 0; never blocks.

## See also

- [Capabilities YAML schema](/docs/data-structures/capabilities-yaml)
- [Hooks index](/docs/hooks/)
