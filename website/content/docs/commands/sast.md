---
title: sast
weight: 50
description: Run Vulnetix SAST analysis only
---

Run Vulnetix SAST analysis only

## Invocation

```
/vulnetix:sast [arguments]
```

Runs:

```bash
vulnetix sast $ARGUMENTS -o json
```

The command is a deterministic CLI wrapper (`disable-model-invocation: true`). Output is JSON; the model summarizes it for the user.

## See also

- [Commands index](/docs/commands/)
