---
description: Authenticate with Vulnetix, or self-serve a free API key if the user has no account
disable-model-invocation: true
allowed-tools: Bash
model: sonnet
---

Verify the Vulnetix CLI is callable (`command -v vulnetix`); if missing, install it self-serve with `bash "${CLAUDE_PLUGIN_ROOT}/hooks/ensure-vulnetix-cli.sh"` (brew → scoop → nix → GitHub releases → go install).

**If the user already has credentials** (org id + api key/secret), authenticate:

```bash
vulnetix auth login $ARGUMENTS
```

Display the JSON and a brief structured summary. Pass through user-supplied flags via `$ARGUMENTS`.

**If the user has no account / no key**, do not guess credentials — run the self-serve registration flow instead: invoke `/vulnetix:get-api-key` (or follow `skills/get-api-key/SKILL.md`), which registers an email at the public Community endpoint and stores the returned credentials. The VDB also works unauthenticated on a shared pool, so a key is optional — it just raises limits.
