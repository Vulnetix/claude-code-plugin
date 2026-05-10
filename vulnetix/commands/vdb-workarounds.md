---
description: Get workaround information for a vulnerability (V2)
disable-model-invocation: true
allowed-tools: Bash
model: sonnet
---

Verify the Vulnetix CLI is callable (`command -v vulnetix`); if missing, fall back to the install priority documented in any Vulnetix skill (brew → scoop → nix → GitHub releases → go install). Then run:

```bash
vulnetix vdb workarounds $ARGUMENTS -V v2 -o json
```

Display the JSON to the user and provide a brief structured summary. Pass through any user-supplied flags via `$ARGUMENTS`.
