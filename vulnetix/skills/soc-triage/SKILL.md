---
name: soc-triage
description: Daily SOC triage feed prioritized for this repo. Pulls Vulnetix's score-driven triage list and cross-references with installed dependencies.
argument-hint: "[--severity high|critical] [--limit N]"
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
---

# Vulnetix SOC Triage Skill

The "daily SOC pull" — fetches Vulnetix's score-driven triage feed, narrows it to ecosystems / packages this repo actually uses (per `.vulnetix/capabilities.yaml`), and produces a ranked action list.

## Step 1: Load capabilities

Read `.vulnetix/capabilities.yaml`. Use `derived.primary_package_manager` and the `repo.*` flags to choose the ecosystem filter. If the file is missing, run `${CLAUDE_PLUGIN_ROOT}/hooks/capabilities-detect.sh` first.

## Step 2: Verify CLI availability

```bash
command -v vulnetix &>/dev/null || (see /vulnetix:vuln Step "CLI Availability" for install)
```

## Step 3: Pull the triage feed

```bash
vulnetix vdb triage $ARGUMENTS -o json
```

Default arguments: `--limit 50`. Honor user-supplied `--severity`, `--ecosystem`, `--in-kev`, `--min-epss`, `--since`, `--sort` flags by passing through `$ARGUMENTS`.

## Step 4: Cross-reference with repo

For each item in the feed:
1. Use **Grep** on lockfiles (matched by `derived.primary_package_manager`) to check if the affected package is present.
2. Mark `In repo?` = direct / transitive / not-found.
3. Cross-reference `.vulnetix/memory.yaml` for prior triage decisions (skip already-decided P3/P4 unless re-flagged).

## Step 5: Render ranked report

Markdown table grouped by P1 / P2 / P3 / P4 (priority tiers from the feed):

```
| ID | Package | Severity | EPSS | KEV | In repo? | Action |
```

Suggested actions per row:
- `In repo? = direct` + KEV → `/vulnetix:fix <id>` (urgent)
- `In repo? = direct` no KEV → `/vulnetix:remediation <id>`
- `In repo? = transitive` → `/vulnetix:safe-harbor-resolver` (agent)
- `In repo? = not-found` but high P1 → log only, no action

## Step 6: Memory update

Append `event: soc-triage` history entries for any newly surfaced vulns (status: under_investigation). Single consolidated write.

## Notes

- Use `-o json` for parseable output. Pipe to `jq` for filtering.
- Honor `derived.detection_stack` — for vulns without fixes, suggest `/vulnetix:detection-rules <id>` only when at least one of `snort`, `suricata`, `yara`, `nuclei` is in the stack.
- For SOAR=stix, suggest `/vulnetix:ioc-pivot <id> --format stix` for high-severity items.
