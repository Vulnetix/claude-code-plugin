---
name: ioc-pivot
description: Pivot from a CVE to indicators of compromise (IPs, ASNs, geos) and merged in-the-wild observation timeline. Optionally export STIX 2.1 for SOAR/SIEM.
argument-hint: <vuln-id>
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
triggers:
  - "ioc"
  - "sightings"
  - "indicators of compromise"
  - "stix"
chain:
  - detection-rules
  - attack-mapping
outputBudget: medium
cooldown: per-session
---

# Vulnetix IOC Pivot Skill

## Conventions

This skill follows [`_lib/contract.md`](../_lib/contract.md): the Vulnetix CLI is auto-installed by hooks, `.vulnetix/capabilities.yaml` is always present, every `vulnetix vdb` call is piped through a verified `jq` filter from [`_lib/jq/`](../_lib/jq/), independent calls run in parallel as concurrent Bash tool calls, and trailing follow-ups are limited to one line. See the contract for output style, memory write rules, and cooldowns.

Builds a SOC-grade IOC view for a single CVE — combines `vdb iocs` (CrowdSec sightings + Shadowserver counts) and `vdb sightings` (merged timeline) into a single report. Exports STIX bundle when the user has a SOAR sink.

## Step 1: Load capabilities

Read `.vulnetix/capabilities.yaml`. Capture `derived.soar` to decide STIX export; capture `derived.detection_stack` to suggest follow-up rule fetches.

## Step 2: Fetch IOCs

```bash
vulnetix vdb iocs "$ARGUMENTS" -o json | jq -f "${CLAUDE_PLUGIN_ROOT}/skills/_lib/jq/iocs.jq"
```

Pass through optional flags: `--country`, `--asn`, `--limit`, `--since`. Capture: top IPs, ASNs, country distribution, ATT&CK techniques observed, Shadowserver scan counts.

## Step 3: Fetch sightings timeline

```bash
vulnetix vdb sightings "$ARGUMENTS" -o json | jq -f "${CLAUDE_PLUGIN_ROOT}/skills/_lib/jq/sightings.jq"
```

Merge timeline events (first-seen, peak, last-seen) by source.

## Step 4: Render SOC report

Sections:
- **Summary** — first-seen, last-seen, peak day, total Shadowserver scans
- **Top IOCs** — IPs / ASNs / countries (top 10 each, in tables)
- **ATT&CK techniques** — list with counts
- **Sources** — CrowdSec, Shadowserver, etc.
- **Timeline** — Mermaid `gantt` or `timeline` diagram if 5+ events

## Step 5: STIX export (conditional)

If `derived.soar == "stix"` OR user passes `--format stix`:

```bash
vulnetix vdb iocs list --cve-id "$ARGUMENTS" --format stix > .vulnetix/iocs/${ARGUMENTS}.stix.json
```

Note the file path in the report and suggest the user import into Splunk / Sentinel / Cortex / Tines.

## Step 6: Suggested follow-ups

- If `detection_stack` non-empty → `/vulnetix:detection-rules $ARGUMENTS`
- If active in-the-wild → `/vulnetix:incident-respond $ARGUMENTS` (agent)
- If installed in repo (cross-check `memory.yaml`) → `/vulnetix:verify-fix $ARGUMENTS` after patch

## Memory update

Append `event: ioc-pivot` to the vuln entry with summary stats (peak day, top country, source count).
