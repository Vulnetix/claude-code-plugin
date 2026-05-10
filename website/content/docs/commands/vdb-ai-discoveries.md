---
title: vdb-ai-discoveries
weight: 50
description: AI-discovered vulnerabilities (researcher leaderboard + per-CVE)
---

AI-discovered vulnerabilities (researcher leaderboard + per-CVE)

## Invocation

```
/vulnetix:vdb-ai-discoveries [arguments]
```

Runs:

```bash
vulnetix vdb ai-discoveries $ARGUMENTS -o json
```

The command is a deterministic CLI wrapper (`disable-model-invocation: true`). Output is JSON; the model summarizes it for the user.

## See also

- [Commands index](/docs/commands/)
