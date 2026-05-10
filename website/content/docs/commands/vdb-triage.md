---
title: vdb-triage
weight: 50
description: Score-driven triage feed (the daily SOC pull)
---

Score-driven triage feed (the daily SOC pull)

## Invocation

```
/vulnetix:vdb-triage [arguments]
```

Runs:

```bash
vulnetix vdb triage $ARGUMENTS -o json
```

The command is a deterministic CLI wrapper (`disable-model-invocation: true`). Output is JSON; the model summarizes it for the user.

## See also

- [Commands index](/docs/commands/)
