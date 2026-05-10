---
name: eol-check
description: Flag end-of-life runtimes and packages in the repo. Surfaces EOL Node, Python, Java, Go, .NET, base images, and key libraries.
argument-hint: "[--strict]"
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep
model: sonnet
triggers:
  - "eol"
  - "end of life"
  - "outdated runtime"
  - "unsupported version"
chain:
  - dep-resolve
  - fix
outputBudget: short
cooldown: per-session
---

# Vulnetix EOL Check Skill

## Conventions

This skill follows [`_lib/contract.md`](../_lib/contract.md): the Vulnetix CLI is auto-installed by hooks, `.vulnetix/capabilities.yaml` is always present, every `vulnetix vdb` call is piped through a verified `jq` filter from [`_lib/jq/`](../_lib/jq/), independent calls run in parallel as concurrent Bash tool calls, and trailing follow-ups are limited to one line. See the contract for output style, memory write rules, and cooldowns.

## Step 1: Load capabilities

Read `.vulnetix/capabilities.yaml`. Use `derived.primary_package_manager` and `repo.dockerfile` to decide which surfaces to scan.

## Step 2: Run gated scan

```bash
vulnetix scan --block-eol -o json
```

Exit code is non-zero on EOL hits. Capture findings.

## Step 3: Cross-check runtimes

For each detected runtime, fetch authoritative dates:

```bash
vulnetix vdb product "<runtime>" -o json   # node, python, java, golang, dotnet
```

## Step 4: Render

```
| Runtime / package | Installed | EOL date | Days past EOL | Action |
| Node.js          | 16.x      | 2023-09-11 | 600          | upgrade to 20 LTS |
```

If `--strict`, also flag versions reaching EOL within 90 days.

## Memory update

`event: eol-check` with EOL items per vuln entry (or a top-level `runtimes` block in memory.yaml if entries don't exist).
