---
name: post-install-scan
description: 'PostToolUse Bash hook: after install commands match (npm/pip/cargo/gem/composer/etc. — 23+ patterns), regenerate the CycloneDX SBOM and scan for new findings. Use when surfacing newly-introduced vulnerabilities immediately after the install command completes.'
event: command
---

# Post-Install-Scan hook

## Use when

- A Bash command matched a known install pattern (PostToolUse).
- The install command succeeded.


Runs after shell commands matching package install patterns to generate an updated SBOM and scan for new vulnerabilities.

## Edge cases & gotchas

- Runs after the install succeeds; failed installs do not trigger.
- CycloneDX SBOM is written to `.vulnetix/sboms/<ISO8601>.cdx.json`.
- Scan is `vulnetix scan --evaluate-sca` — focused on dep additions; does not re-run SAST/secrets.
- Cooldown is install-command-keyed, so `npm install` followed by `npm install x` both fire.
- For 10K+ dep installs (rare), the scan can take 30s; results are not blocking.
