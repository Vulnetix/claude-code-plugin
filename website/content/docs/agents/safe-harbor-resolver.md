---
title: Safe Harbor Resolver
weight: 50
description: Resolve dep-version conflicts that block a fix; tries override → safe-harbour inline → workaround paths.
---

Resolve dep-version conflicts that block a fix; tries override → safe-harbour inline → workaround paths.

## Invocation

```
@safe-harbor-resolver <args>
```

## Behavior

See [`agents/safe-harbor-resolver.md`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/agents/safe-harbor-resolver.md) for the full multi-stage workflow. Reads `.vulnetix/capabilities.yaml` and `.vulnetix/memory.yaml`; uses `--disable-memory` on inner CLI calls and performs a single consolidated memory write at the end.

## See also

- [Agents index](/docs/agents/)
