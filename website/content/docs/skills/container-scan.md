---
title: Container Scan
weight: 50
description: Analyze Dockerfile / Containerfile / compose. Composes with Trivy / Grype / Syft when present.
---

Analyze Dockerfile / Containerfile / compose. Composes with Trivy / Grype / Syft when present.

## Invocation

```
/vulnetix:container-scan [--paths Dockerfile] [--image registry/img:tag]
```

## Capabilities-aware

Reads `.vulnetix/capabilities.yaml` first and scopes the Vulnetix CLI calls and external integrations (snort, yara, nuclei, semgrep, syft, grype, trivy, cosign) to what the system and repo support. The session-start hook keeps that file fresh; force a refresh with `/vulnetix:capabilities-detect` or `VULNETIX_FORCE_DETECT=1`.

## Workflow

See the [SKILL.md source](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/skills/container-scan/SKILL.md) for the full workflow. Key steps: load capabilities, run the relevant `vulnetix` subcommand(s) with `-o json`, render the result, and update `.vulnetix/memory.yaml` (where applicable).

## See also

- [Capabilities YAML schema](/docs/data-structures/capabilities-yaml)
- [Skills index](/docs/skills/)
