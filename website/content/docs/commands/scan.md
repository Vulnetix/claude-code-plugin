---
title: scan
weight: 50
description: Run a full Vulnetix scan (configurable across SCA + SAST + secrets + license + container + IaC)
---

Run a full Vulnetix scan (configurable across SCA + SAST + secrets + license + container + IaC)

## Invocation

```
/vulnetix:scan [arguments]
```

Runs:

```bash
vulnetix scan $ARGUMENTS -o json
```

The command is a deterministic CLI wrapper (`disable-model-invocation: true`). Output is JSON; the model summarizes it for the user.

## See also

- [Commands index](/docs/commands/)
