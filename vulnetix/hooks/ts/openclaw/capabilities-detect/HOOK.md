---
name: capabilities-detect
description: Probe system binaries and repo signals at session start, persist to .vulnetix/capabilities.yaml so other surfaces only invoke meaningful CLI features
event: agent:bootstrap
---

Runs the Vulnetix capabilities detector on session start. Probes for `nuclei`, `snort`, `suricata`, `yara`, `semgrep`, `syft`, `grype`, `trivy`, package managers, and repo signals (manifests, Dockerfiles, IaC, CI configs). Result lives at `.vulnetix/capabilities.yaml` and is read by every other skill/hook/command/agent to scope which `vulnetix` subcommands and integrations are relevant. Refreshes lazily (24h TTL); force with `VULNETIX_FORCE_DETECT=1`.
