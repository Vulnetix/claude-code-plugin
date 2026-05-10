---
name: safe-version
description: Find the safest currently-published version of a package across an ecosystem — newest version free of known vulnerabilities.
argument-hint: <package-name> [--ecosystem npm|pypi|...] [--max-major-bump 1]
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep
model: sonnet
triggers:
  - "safe version"
  - "newest safe"
  - "latest safe"
  - "upgrade target"
chain:
  - fix
  - dep-resolve
outputBudget: short
cooldown: per-session
---

# Vulnetix Safe Version Skill

## Conventions

This skill follows [`_lib/contract.md`](../_lib/contract.md): the Vulnetix CLI is auto-installed by hooks, `.vulnetix/capabilities.yaml` is always present, every `vulnetix vdb` call is piped through a verified `jq` filter from [`_lib/jq/`](../_lib/jq/), independent calls run in parallel as concurrent Bash tool calls, and trailing follow-ups are limited to one line. See the contract for output style, memory write rules, and cooldowns.

## Step 1: Load capabilities

Default `--ecosystem` from `derived.primary_package_manager`.

## Step 2: Pull versions and vulns

```bash
vulnetix vdb versions "$PACKAGE" --ecosystem "$ECO" -o json | jq -f "${CLAUDE_PLUGIN_ROOT}/skills/_lib/jq/versions.jq"
vulnetix vdb vulns "$PACKAGE" -o json | jq -f "${CLAUDE_PLUGIN_ROOT}/skills/_lib/jq/vulns.jq"
vulnetix vdb purl "pkg:${ECO}/${PACKAGE}@latest" -o json | jq -f "${CLAUDE_PLUGIN_ROOT}/skills/_lib/jq/purl.jq"
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
