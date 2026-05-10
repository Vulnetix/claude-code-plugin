---
name: safe-version
description: Find the safest currently-published version of a package across an ecosystem — newest version free of known vulnerabilities.
argument-hint: <package-name> [--ecosystem npm|pypi|...] [--max-major-bump 1]
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep
model: sonnet
---

# Vulnetix Safe Version Skill

## Step 1: Load capabilities

Default `--ecosystem` from `derived.primary_package_manager`.

## Step 2: Pull versions and vulns

```bash
vulnetix vdb versions "$PACKAGE" --ecosystem "$ECO" -o json
vulnetix vdb vulns "$PACKAGE" -o json
vulnetix vdb purl "pkg:${ECO}/${PACKAGE}@latest" -o json
```

## Step 3: Compute safe set

For each version in the version list:
- Mark unsafe if any known vuln's affected range includes it
- Apply `--max-major-bump` cap (default 1) to limit churn

Pick the newest safe version that doesn't exceed the major-bump cap.

## Step 4: Render

```
Safe version of <package> (<ecosystem>):
Currently installed: <ver>
Latest published:   <ver>
Recommended safe:   <ver>   (skipping vulnerable: 4.16.0–4.17.2 affected by CVE-…)
Major-bump cap:     <n>
```

Suggest `/vulnetix:fix` or `/vulnetix:dep-resolve` to apply the bump.

## No memory writes

Read-only.
