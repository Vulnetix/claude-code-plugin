---
name: typosquat-check
description: Detect malware and typosquats among installed dependencies (and prospective additions).
argument-hint: "[<package-name>] | [--installed]"
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
---

# Vulnetix Typosquat Check Skill

## Step 1: Decide mode

- Single-package: `$ARGUMENTS` is a name → check just that.
- `--installed`: read lockfile (per `derived.primary_package_manager`), check every direct dep.

## Step 2: Run gated scan + AI-malware lookup

```bash
vulnetix scan --block-malware -o json
vulnetix vdb ai-malware list -o json
vulnetix vdb packages search "$PACKAGE" --ecosystem "$ECO" -o json   # for similarity hits
```

The `packages search` response includes typosquat-similarity scores against well-known package names.

## Step 3: Render

```
| Package | Version | Verdict | Reason |
| react-utill | 1.0.0 | BLOCK | typosquat of react-util (similarity 0.92), 0 stars, 14d old |
```

Verdicts: ALLOW / WARN / BLOCK.

## Step 4: Memory + .gitignore note

Append `event: typosquat-check` with verdicts to memory. If any BLOCK, surface a strong suggestion to remove the package and check git history (`git log -p -- <package-manifest-path>`).
