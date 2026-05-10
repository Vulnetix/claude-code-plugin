---
description: AI-discovered vulnerabilities (researcher leaderboard + per-CVE)
disable-model-invocation: true
allowed-tools: Bash
model: sonnet
---

Verify the Vulnetix CLI is callable (`command -v vulnetix`); if missing, fall back to the install priority documented in any Vulnetix skill (brew → scoop → nix → GitHub releases → go install). Then run:

```bash
vulnetix vdb ai-discoveries $ARGUMENTS -o json
```

Display the JSON to the user and provide a brief structured summary. Pass through any user-supplied flags via `$ARGUMENTS`.
