---
name: dep-add-guard
description: Risk gate before adding a dependency. Combines vuln history, malware/typosquat checks, license, EOL, and maintainer health into one verdict.
argument-hint: <package-name> [--version X] [--ecosystem npm|pypi|...]
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
triggers:
  - "add dependency"
  - "install package"
  - "new dep"
  - "add library"
  - "require package"
chain:
  - package-search
  - dep-resolve
outputBudget: short
cooldown: per-session
---

# Vulnetix Dependency-Add Guard Skill

## Conventions

This skill follows [`_lib/contract.md`](../_lib/contract.md): the Vulnetix CLI is auto-installed by hooks, `.vulnetix/capabilities.yaml` is always present, every `vulnetix vdb` call is piped through a verified `jq` filter from [`_lib/jq/`](../_lib/jq/), independent calls run in parallel as concurrent Bash tool calls, and trailing follow-ups are limited to one line. See the contract for output style, memory write rules, and cooldowns.

Refines `/vulnetix:package-search` into an explicit "should I add this?" verdict.

## Step 1: Load capabilities

Read `.vulnetix/capabilities.yaml`. Default `--ecosystem` from `derived.primary_package_manager` if not provided.

## Step 2: Parallel intelligence pulls

```bash
vulnetix vdb packages search "$PACKAGE" --ecosystem "$ECO" -o json & | jq -f "${CLAUDE_PLUGIN_ROOT}/skills/_lib/jq/packages.jq"
vulnetix vdb vulns "$PACKAGE" -o json & | jq -f "${CLAUDE_PLUGIN_ROOT}/skills/_lib/jq/vulns.jq"
vulnetix vdb ai-malware list --package "$PACKAGE" -o json & | jq -f "${CLAUDE_PLUGIN_ROOT}/skills/_lib/jq/ai-list.jq"
vulnetix vdb purl "pkg:${ECO}/${PACKAGE}@${VERSION:-latest}" -o json & | jq -f "${CLAUDE_PLUGIN_ROOT}/skills/_lib/jq/purl.jq"
wait
```

## Step 3: Apply gates

Verdict = WORST of these checks:
- **block**: known malware/typosquat hit
- **block**: critical CVE in target version with no fix
- **warn**: copyleft license against permissive codebase
- **warn**: low maintainer-health (single maintainer, no commits in 12mo, low downloads)
- **warn**: EOL upstream
- **warn**: version-lag (>3 minor versions behind)
- **allow**: none of the above

## Step 4: Render

```
Dependency: <package>@<version> (<ecosystem>)

Verdict: ALLOW | WARN | BLOCK

| Check | Result | Detail |
| Vuln history | 3 known | 0 affecting target version |
| Malware / typosquat | clean | no AI-malware family hit |
| License | MIT | OK |
| Maintainer health | 1 maintainer, last commit 14mo ago | warn |
| EOL | not EOL | OK |
| Version lag | latest=4.2.0, requested=4.0.1 | OK |
```

If BLOCK, refuse and suggest alternatives via `vulnetix vdb packages search --ecosystem $ECO --safe`.

## Memory update

Append `event: dep-add-guard` to `.vulnetix/memory.yaml` with the verdict and rationale.
