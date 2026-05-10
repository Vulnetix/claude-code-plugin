---
name: license-check
description: Detect license conflicts and policy violations across dependencies. Outputs SPDX SBOM with license findings.
argument-hint: "[--policy permissive|copyleft-aware|strict]"
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
---

# Vulnetix License Check Skill

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
