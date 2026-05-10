---
title: Compliance Bundler
weight: 50
description: Build a complete compliance bundle (SBOM, SPDX, SARIF, VEX) with optional sign + upload.
---

Build a complete compliance bundle (SBOM, SPDX, SARIF, VEX) with optional sign + upload.

## Invocation

```
@compliance-bundler <args>
```

## Behavior

See [`agents/compliance-bundler.md`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/agents/compliance-bundler.md) for the full multi-stage workflow. Reads `.vulnetix/capabilities.yaml` and `.vulnetix/memory.yaml`; uses `--disable-memory` on inner CLI calls and performs a single consolidated memory write at the end.

## See also

- [Agents index](/docs/agents/)
