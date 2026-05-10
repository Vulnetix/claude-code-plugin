---
title: Dep-Add Guard
weight: 50
description: Risk gate before adding a dependency. Composes vuln history, malware/typosquat, license, EOL, and maintainer health.
---

Risk gate before adding a dependency. Composes vuln history, malware/typosquat, license, EOL, and maintainer health.

## Invocation

```
/vulnetix:dep-add-guard <package> [--version X] [--ecosystem npm|pypi|...]
```

## Capabilities-aware

Reads `.vulnetix/capabilities.yaml` first and scopes the Vulnetix CLI calls and external integrations (snort, yara, nuclei, semgrep, syft, grype, trivy, cosign) to what the system and repo support. The session-start hook keeps that file fresh; force a refresh with `/vulnetix:capabilities-detect` or `VULNETIX_FORCE_DETECT=1`.

## Workflow

See the [SKILL.md source](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/skills/dep-add-guard/SKILL.md) for the full workflow. Key steps: load capabilities, run the relevant `vulnetix` subcommand(s) with `-o json`, render the result, and update `.vulnetix/memory.yaml` (where applicable).

## See also

- [Capabilities YAML schema](/docs/data-structures/capabilities-yaml)
- [Skills index](/docs/skills/)
