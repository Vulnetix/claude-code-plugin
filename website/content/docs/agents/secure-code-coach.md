---
title: Secure Code Coach
weight: 50
description: Long-running coach for a feature branch — proactive SAST/secret/secure-code reminders.
---

Long-running coach for a feature branch — proactive SAST/secret/secure-code reminders.

## Invocation

```
@secure-code-coach <args>
```

## Behavior

See [`agents/secure-code-coach.md`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/agents/secure-code-coach.md) for the full multi-stage workflow. Reads `.vulnetix/capabilities.yaml` and `.vulnetix/memory.yaml`; uses `--disable-memory` on inner CLI calls and performs a single consolidated memory write at the end.

## See also

- [Agents index](/docs/agents/)
