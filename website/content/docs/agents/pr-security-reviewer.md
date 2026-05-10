---
title: PR Security Reviewer
weight: 50
description: Comprehensive pre-merge review composing SAST, SCA, secrets, container, IaC, license.
---

Comprehensive pre-merge review composing SAST, SCA, secrets, container, IaC, license.

## Invocation

```
@pr-security-reviewer <args>
```

## Behavior

See [`agents/pr-security-reviewer.md`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/agents/pr-security-reviewer.md) for the full multi-stage workflow. Reads `.vulnetix/capabilities.yaml` and `.vulnetix/memory.yaml`; uses `--disable-memory` on inner CLI calls and performs a single consolidated memory write at the end.

## See also

- [Agents index](/docs/agents/)
