---
name: dashboard
description: 'Vulnerability tracking dashboard: read `.vulnetix/memory.yaml`, classify by status (under_investigation, affected, fixed, not_affected) and decision (fix-applied, risk-accepted, deferred, mitigated, inlined, risk-avoided, not-affected, risk-transferred), surface CWSS-priority sorted top entries. Use when reviewing what Pix has tracked across sessions, auditing past triage decisions, or onboarding to a repo with prior security history.'
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep
model: haiku
triggers:
  - "dashboard"
  - "status"
  - "what vulns"
  - "tracked vulnerabilities"
chain:
  - soc-triage
  - vuln
outputBudget: medium
cooldown: per-session
---

# Vulnetix Vulnerability Dashboard

## Use when

- You want a single view of every vulnerability tracked in this repo, grouped by status and decision.
- Someone asks "where did we leave triage last week?".
- Onboarding to a repo and you want to see prior security decisions before duplicating work.
- You want to spot stale `under_investigation` items that need re-triaging.
- Pre-release: confirm no high-severity entries remain open before tagging.

## Don't use for

- Fetching new vulnerability data — use `/vulnetix:soc-triage` or `/vulnetix:vuln`.
- Applying fixes — use `/vulnetix:fix`.
- Cross-repo dashboards — this skill reads only the current repo's memory file.

## Conventions

This skill follows `skills/_lib/contract.md`: the Vulnetix CLI is auto-installed by hooks, `.vulnetix/capabilities.yaml` is always present, every `vulnetix vdb` call is piped through a verified `jq` filter from `skills/_lib/jq/`, independent calls run in parallel as concurrent Bash tool calls, and trailing follow-ups are limited to one line. See the contract for output style, memory write rules, and cooldowns.


This skill reads `.vulnetix/memory.yaml` and displays a comprehensive vulnerability status report. It is read-only and does not modify any files.

## Workflow

### Step 1: Load Memory

1. Use **Glob** to check if `.vulnetix/memory.yaml` exists in the repo root
2. If it does not exist, display: **"No vulnerability data found. Run `/vulnetix:vuln <package>` or `/vulnetix:exploits-search` to start tracking."** and stop.
3. Use **Read** to load the full contents of `.vulnetix/memory.yaml`

### Step 2: Parse and Categorize

From the `vulnerabilities:` section, categorize each entry:

**Open (unresolved):**
- `status: affected` -- "Vulnerable"
- `status: under_investigation` -- "Investigating"

**Resolved:**
- `status: fixed` -- "Fixed"
- `status: not_affected` -- "Not affected"
- Entries with `decision.choice: risk-accepted` -- "Risk accepted"
- Entries with `decision.choice: deferred` -- "Deferred"

From the `manifests:` section, collect manifest tracking info.

### Step 3: Display Summary Header

```
Vulnetix Security Dashboard
============================
Open: <N> (<X> vulnerable, <Y> investigating)
Resolved: <N> (<X> fixed, <Y> not affected, <Z> risk-accepted, <W> deferred)
Manifests tracked: <N> (last scan: <timestamp>)
```

If there are zero vulnerabilities and zero manifests, display: **"Clean slate -- no vulnerabilities tracked yet."**

### Step 4: Open Vulnerabilities Table

If there are open vulnerabilities, display them sorted by CWSS priority (P1 first), then by severity:

```
Open Vulnerabilities
--------------------
| ID | Package | Severity | Status | Priority | Decision |
|----|---------|----------|--------|----------|----------|
| CVE-2021-44228 | log4j-core | critical | Vulnerable | P1 (87.5) | investigating |
| GHSA-xxxx-yyyy | express | high | Investigating | P2 (62.0) | investigating |
```

For each column:
- **ID**: Primary vulnerability key
- **Package**: `package` field
- **Severity**: `severity` field
- **Status**: Developer-friendly status (see VEX mapping above)
- **Priority**: `cwss.priority` and `cwss.score` if available, otherwise "--"
- **Decision**: `decision.choice` if available, otherwise "--"

### Step 5: Resolved Vulnerabilities Table

If there are resolved vulnerabilities, display them:

```
Resolved Vulnerabilities
------------------------
| ID | Package | Severity | Resolution | Decision | Date |
|----|---------|----------|------------|----------|------|
| CVE-2023-1234 | lodash | high | Fixed | fix-applied | 2024-01-15 |
```

For the **Date** column, use the most recent `history` entry timestamp, or `discovery.date` as fallback.

### Step 6: Manifest Tracking

If manifests are tracked, display:

```
Tracked Manifests
-----------------
| Manifest | Ecosystem | Last Scanned | Vulns Found |
|----------|-----------|--------------|-------------|
| package.json | npm | 2024-01-15T10:30:00Z | 3 |
| go.mod | go | 2024-01-15T10:31:00Z | 0 |
```

### Step 7: Suggested Actions

For each open vulnerability (up to 5), suggest a next action based on its state:

- Has no `threat_model` or `cwss`: `"/vulnetix:exploits <id>"` -- get exploit analysis and priority scoring
- Has `cwss` but no fix applied: `"/vulnetix:fix <id>"` -- get fix intelligence
- Has decision `risk-accepted`, `deferred`, or `mitigated` (non-patch): `"vulnetix vdb traffic-filters <id>"` -- get Snort rules for network-level mitigation
- General: `"/vulnetix:remediation <id>"` -- get a full remediation plan

If there are more than 5 open vulns, add: `"Use /vulnetix:exploits-search to find exploited vulnerabilities across your ecosystem."`

Always end with: `"Use /vulnetix:vuln <id> for detailed info on any vulnerability."`

## Edge cases & gotchas

- Reads `.vulnetix/memory.yaml` only. If the file is missing, the skill exits silently — run `/vulnetix:soc-triage` or `/vulnetix:vuln` first to populate.
- `decision.choice` is a closed enum; entries with arbitrary strings render under "Unknown decision".
- Mermaid pie chart of decisions is auto-skipped if the total is < 3 (avoids rendering near-empty visuals).
- For repos with > 200 tracked vulns, the dashboard caps the table at 50 rows sorted by CWSS — full list is in `memory.yaml`.
- CWSS scores can be missing for entries that were created by `/vulnetix:vuln` lookup-only mode; the dashboard sorts those to the bottom.
