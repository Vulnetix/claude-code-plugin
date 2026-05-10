---
title: Git Push Gate
weight: 50
description: Pre-push secret-scan + open-finding summary.
---

Pre-push secret-scan + open-finding summary.

## Trigger

PreToolUse on Bash

## Behavior

See [`hooks/git-push-gate.sh`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/hooks/git-push-gate.sh) and [`hooks/ts/openclaw/git-push-gate/HOOK.md`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/hooks/ts/openclaw/git-push-gate/HOOK.md). The hook reads `.vulnetix/capabilities.yaml` and skips work when the relevant binaries / repo signals are absent. Always exits 0; never blocks.

## See also

- [Capabilities YAML schema](/docs/data-structures/capabilities-yaml)
- [Hooks index](/docs/hooks/)
