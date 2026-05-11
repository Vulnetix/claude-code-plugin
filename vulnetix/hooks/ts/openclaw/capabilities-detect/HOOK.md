---
name: capabilities-detect
description: 'SessionStart probe: detect 41 security binaries (nuclei, snort, yara, semgrep, syft, grype, trivy, cosign, gh, package managers) plus 30 repo signals (manifests, Dockerfiles, IaC, CI, rule files). Write `.vulnetix/capabilities.yaml` so every downstream skill can scope its CLI calls and external integrations. Use when sessions start (auto), or force with VULNETIX_FORCE_DETECT=1.'
event: agent:bootstrap
---

# Capabilities-Detect hook

## Use when

- A new session starts and `.vulnetix/capabilities.yaml` is missing or older than 24h.
- A manifest file was just edited and downstream skills should re-scope.
- A new security binary was just installed — invalidate the cache.


Runs the Vulnetix capabilities detector on session start. Probes for `nuclei`, `snort`, `suricata`, `yara`, `semgrep`, `syft`, `grype`, `trivy`, package managers, and repo signals (manifests, Dockerfiles, IaC, CI configs). Result lives at `.vulnetix/capabilities.yaml` and is read by every other skill/hook/command/agent to scope which `vulnetix` subcommands and integrations are relevant. Refreshes lazily (24h TTL); force with `VULNETIX_FORCE_DETECT=1`.

## Edge cases & gotchas

- 24-hour cache via mtime — sub-second re-detect is suppressed.
- `command -v` runs in the session shell; PATH manipulated by zsh autoload or fish functions may miss tools.
- Find pass is depth-limited (4 levels, excluding `.git`/`node_modules`/`.vulnetix`) — deep monorepo subfolders may not be detected.
- Authentication status uses `vulnetix auth status -o json` and treats network failure as `unauthenticated`.
- No-op exit on missing `jq` — silent fallback prevents hook errors.
