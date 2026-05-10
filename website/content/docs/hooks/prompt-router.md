---
title: Prompt Router
weight: 50
description: Detects security-relevant keywords in user prompts and suggests the matching Pix skill.
---

Detects security-relevant keywords in user prompts and suggests the matching Pix skill.

## Trigger

UserPromptSubmit

## Behavior

See [`hooks/prompt-router.sh`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/hooks/prompt-router.sh) and [`hooks/ts/openclaw/prompt-router/HOOK.md`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/hooks/ts/openclaw/prompt-router/HOOK.md). The hook reads `.vulnetix/capabilities.yaml` and skips work when the relevant binaries / repo signals are absent. Always exits 0; never blocks.

## See also

- [Capabilities YAML schema](/docs/data-structures/capabilities-yaml)
- [Hooks index](/docs/hooks/)
