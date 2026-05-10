---
title: Incident Responder
weight: 50
description: SOC playbook for an actively exploited CVE — sightings, IOCs, ATT&CK, detection rules, patch path, VEX.
---

SOC playbook for an actively exploited CVE — sightings, IOCs, ATT&CK, detection rules, patch path, VEX.

## Invocation

```
@incident-responder <args>
```

## Behavior

See [`agents/incident-responder.md`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/agents/incident-responder.md) for the full multi-stage workflow. Reads `.vulnetix/capabilities.yaml` and `.vulnetix/memory.yaml`; uses `--disable-memory` on inner CLI calls and performs a single consolidated memory write at the end.

## See also

- [Agents index](/docs/agents/)
