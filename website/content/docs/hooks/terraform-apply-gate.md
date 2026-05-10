---
title: Terraform Apply Gate
weight: 50
description: Quick IaC scan before terraform/tofu apply.
---

Quick IaC scan before terraform/tofu apply.

## Trigger

PreToolUse on Bash

## Behavior

See [`hooks/terraform-apply-gate.sh`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/hooks/terraform-apply-gate.sh) and [`hooks/ts/openclaw/terraform-apply-gate/HOOK.md`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/hooks/ts/openclaw/terraform-apply-gate/HOOK.md). The hook reads `.vulnetix/capabilities.yaml` and skips work when the relevant binaries / repo signals are absent. Always exits 0; never blocks.

## See also

- [Capabilities YAML schema](/docs/data-structures/capabilities-yaml)
- [Hooks index](/docs/hooks/)
