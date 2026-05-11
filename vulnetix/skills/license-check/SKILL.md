---
name: license-check
description: 'Package license analysis — detect copyleft conflicts against a permissive policy, surface AGPL / SSPL / GPL contaminants, output SPDX SBOM with per-package license findings. Use when auditing a release for license compliance, vetting a new dependency''s license, building an OSS-attribution document, or producing a customer-facing license disclosure.'
argument-hint: "[--policy permissive|copyleft-aware|strict]"
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
triggers:
  - "license check"
  - "license conflict"
  - "license policy"
  - "copyleft"
chain:
  - compliance-report
outputBudget: short
cooldown: per-session
---

# Vulnetix License Check Skill

## Use when

- Pre-release: confirm no copyleft contaminants in a permissive-licensed product.
- Vetting a new dep's license before adoption.
- Building an OSS attribution document (NOTICE file).
- Producing a customer-facing license disclosure.
- Quarterly compliance review with `--policy strict` to catch any non-allowlisted licenses.

## Don't use for

- Vulnerability scanning — use `/vulnetix:sca-scan`.
- License text retrieval — use the package manager directly (`npm view <pkg> license`).

## Conventions

This skill follows [`_lib/contract.md`](../_lib/contract.md): the Vulnetix CLI is auto-installed by hooks, `.vulnetix/capabilities.yaml` is always present, every `vulnetix vdb` call is piped through a verified `jq` filter from [`_lib/jq/`](../_lib/jq/), independent calls run in parallel as concurrent Bash tool calls, and trailing follow-ups are limited to one line. See the contract for output style, memory write rules, and cooldowns.

## Step 1: Run license analysis

```bash
vulnetix license -o json-spdx > .vulnetix/licenses.${TIMESTAMP}.spdx.json
```

## Step 2: Apply policy

Default policy:
- **permissive**: flag GPL-*, AGPL-*, LGPL-* against MIT/Apache-2.0/BSD codebase
- **copyleft-aware**: flag AGPL-* and SSPL-1.0
- **strict**: flag any non-allowlisted license; allowlist = MIT, Apache-2.0, BSD-2/3-Clause, ISC, MPL-2.0

User can override via `--policy`. Accept user-supplied allowlist via `.vulnetix/license-policy.yaml` if present.

## Step 3: Render

```
| Package | Version | License | Policy verdict | Action |
```

Conflicts highlighted. Suggest replacement packages for blocked licenses (consult `vulnetix vdb packages search <name> --license <permitted>` if needed).

## Step 4: Compliance bundle hint

If `--bundle` flag provided, also output the file path so `/vulnetix:compliance-report` can pick it up.

## Memory update

`.vulnetix/licenses/<timestamp>.summary.yaml` with conflict counts.

## Edge cases & gotchas

- `--policy permissive` flags GPL-* / AGPL-* / LGPL-* against an MIT/Apache codebase; `--policy strict` allowlists only MIT, Apache-2.0, BSD-2/3-Clause, ISC, MPL-2.0.
- Custom allowlist via `.vulnetix/license-policy.yaml` overrides the built-in policy.
- License detection uses package metadata; dual-licensed packages (MIT OR Apache-2.0) are reported as the FIRST license unless the policy file says otherwise.
- SPDX expression parsing handles common patterns (MIT, Apache-2.0, BSD-3-Clause) but not custom non-SPDX strings like "see LICENSE file" — those flag as "Unknown".
- Transitive deps are included by default; pass `--direct-only` to scope to top-level packages.
- License findings DO NOT include legal review — flag them for legal counsel, do not auto-approve based on the skill output.
