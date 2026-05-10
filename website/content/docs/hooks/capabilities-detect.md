---
title: Capabilities Detect
weight: 50
description: SessionStart probe of system binaries and repo signals; persists to .vulnetix/capabilities.yaml.
---

SessionStart probe of system binaries and repo signals; persists to .vulnetix/capabilities.yaml.

## Trigger

SessionStart (24h TTL; force with VULNETIX_FORCE_DETECT=1)

## Behavior

See [`hooks/capabilities-detect.sh`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/hooks/capabilities-detect.sh) and [`hooks/ts/openclaw/capabilities-detect/HOOK.md`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/hooks/ts/openclaw/capabilities-detect/HOOK.md). The hook reads `.vulnetix/capabilities.yaml` and skips work when the relevant binaries / repo signals are absent. Always exits 0; never blocks.

## See also

- [Capabilities YAML schema](/docs/data-structures/capabilities-yaml)
- [Hooks index](/docs/hooks/)
