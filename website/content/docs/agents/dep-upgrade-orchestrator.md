---
title: Dep Upgrade Orchestrator
weight: 50
description: End-to-end dependency upgrade across all manifests with verification and conflict resolution.
---

End-to-end dependency upgrade across all manifests with verification and conflict resolution.

## Invocation

```
@dep-upgrade-orchestrator <args>
```

## Behavior

See [`agents/dep-upgrade-orchestrator.md`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/agents/dep-upgrade-orchestrator.md) for the full multi-stage workflow. Reads `.vulnetix/capabilities.yaml` and `.vulnetix/memory.yaml`; uses `--disable-memory` on inner CLI calls and performs a single consolidated memory write at the end.

## See also

- [Agents index](/docs/agents/)
