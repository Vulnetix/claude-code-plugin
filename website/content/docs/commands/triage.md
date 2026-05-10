---
title: triage
weight: 50
description: Triage vulnerabilities from GitHub alerts or Vulnetix VDB
---

Triage vulnerabilities from GitHub alerts or Vulnetix VDB

## Invocation

```
/vulnetix:triage [arguments]
```

Runs:

```bash
vulnetix triage $ARGUMENTS -o json
```

The command is a deterministic CLI wrapper (`disable-model-invocation: true`). Output is JSON; the model summarizes it for the user.

## See also

- [Commands index](/docs/commands/)
