---
name: eol-check
description: 'End-of-life detection for runtimes (Node, Python, Java, Go, .NET) and key packages — surfaces past-EOL items, items reaching EOL within 90 days, and EOL base images for containers. Use when planning a runtime upgrade, auditing for unsupported versions, gating a deploy against EOL deps, or producing a remediation roadmap.'
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

## Use when

- Quarterly upgrade planning: which runtimes hit EOL in the next 90 days?
- Audit: any past-EOL runtimes in production?
- CI gate: block deploys if any EOL runtime is detected.
- Container base-image EOL check (alpine 3.16, debian 10, etc.).
- Cross-reference: an EOL runtime + an unpatched CVE = critical priority.

## Don't use for

- Vulnerability scanning — use `/vulnetix:sca-scan` or `/vulnetix:soc-triage`.
- License auditing — use `/vulnetix:license-check`.

## Conventions

This skill follows `skills/_lib/contract.md`: the Vulnetix CLI is auto-installed by hooks, `.vulnetix/capabilities.yaml` is always present, every `vulnetix vdb` call is piped through a verified `jq` filter from `skills/_lib/jq/`, independent calls run in parallel as concurrent Bash tool calls, and trailing follow-ups are limited to one line. See the contract for output style, memory write rules, and cooldowns.

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

## Edge cases & gotchas

- `vulnetix scan --block-eol` exits non-zero on EOL hits — wrap with `|| true` to capture without aborting.
- EOL dates are from `vulnetix vdb product` — authoritative for major runtimes, less complete for niche libraries.
- `--strict` mode flags items reaching EOL within 90 days. Default mode only flags past-EOL.
- Container base images need a Dockerfile/Containerfile in the repo; the skill cannot scan a `--image` registry tag without one.
- For runtimes with overlapping LTS schedules (Node 18 vs 20), EOL dates can shift; re-run periodically rather than caching.
- Output flags EOL but does not propose an upgrade path — pair with `/vulnetix:safe-version` for the recommended target.
