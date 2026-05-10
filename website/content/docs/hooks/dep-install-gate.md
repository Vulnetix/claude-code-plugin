---
title: Dep Install Gate
weight: 50
description: Quick vuln/malware check before npm/pnpm/yarn/pip/uv/cargo/go/gem/composer add commands.
---

Quick vuln/malware check before npm/pnpm/yarn/pip/uv/cargo/go/gem/composer add commands.

## Trigger

PreToolUse on Bash

## Behavior

See [`hooks/dep-install-gate.sh`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/hooks/dep-install-gate.sh) and [`hooks/ts/openclaw/dep-install-gate/HOOK.md`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/hooks/ts/openclaw/dep-install-gate/HOOK.md). The hook reads `.vulnetix/capabilities.yaml` and skips work when the relevant binaries / repo signals are absent. Always exits 0; never blocks.

## See also

- [Capabilities YAML schema](/docs/data-structures/capabilities-yaml)
- [Hooks index](/docs/hooks/)
