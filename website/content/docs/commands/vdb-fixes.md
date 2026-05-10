---
title: vdb-fixes
weight: 50
description: Get fix data (patches, advisories, distro patches) for a vulnerability
---

Get fix data (patches, advisories, distro patches) for a vulnerability

## Invocation

```
/vulnetix:vdb-fixes [arguments]
```

Runs:

```bash
vulnetix vdb fixes $ARGUMENTS -o json
```

The command is a deterministic CLI wrapper (`disable-model-invocation: true`). Output is JSON; the model summarizes it for the user.

## See also

- [Commands index](/docs/commands/)
