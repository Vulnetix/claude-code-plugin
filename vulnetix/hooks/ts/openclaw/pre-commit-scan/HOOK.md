---
name: pre-commit-scan
description: 'PreToolUse Bash hook on `git commit`: extract staged manifest files, launch background VDB package searches, report results without blocking the commit. Use when surfacing risky packages staged for commit without slowing the workflow.'
event: command
---

# Pre-Commit-Scan hook

## Use when

- A Bash command matches `git commit`.
- Staged files include a known manifest.


Intercepts shell commands matching git commit patterns and runs the Vulnetix pre-commit vulnerability scan.

## Edge cases & gotchas

- Always exits 0; never blocks the commit.
- Up to 50 packages extracted per fire (per repo); larger diffs are truncated.
- Lock files are skipped (too noisy).
- Async VDB calls — results in `.vulnetix/scans/pre-commit.<ISO8601>.packages.json`. Slow on community-tier rate limits.
- Memory file updated with `scan_source: hook` so dashboards can distinguish auto-scans from interactive runs.
