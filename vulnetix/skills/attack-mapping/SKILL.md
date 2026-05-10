---
name: attack-mapping
description: Map vulnerabilities in this repo to MITRE ATT&CK techniques. Produces a heatmap of techniques observed across tracked CVEs.
argument-hint: "[<vuln-id>] | [--all-tracked]"
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
---

# Vulnetix ATT&CK Mapping Skill

Produces an ATT&CK technique view of repo risk. Run with a single vuln-id for a focused mapping, or `--all-tracked` to roll up every entry in `.vulnetix/memory.yaml`.

## Step 1: Decide mode

If `$ARGUMENTS` matches a vuln-id pattern → single mode. Else if it contains `--all-tracked` → roll-up mode reading every `vulnerabilities.*` entry in `.vulnetix/memory.yaml` (skip those with status `not_affected` or `fixed`).

## Step 2: Fetch ATT&CK data per vuln

```bash
vulnetix vdb attack-techniques "$VULN_ID" -o json
```

Capture: technique IDs (T####), tactic, sub-technique, observed-in-wild count.

## Step 3: Render

**Single mode** — table of techniques with tactic + observation count. Mermaid flowchart from kill-chain tactic → technique → vuln.

**Roll-up mode** — a heatmap-style table:

```
| Technique | Tactic | Vuln count | Top affected packages |
|-----------|--------|-----------|----------------------|
| T1190 | Initial Access | 5 | log4j-core, struts2 |
```

Ranking: by vuln count descending. Top 20 only; total in summary footer.

## Step 4: Suggested follow-ups

- For high-frequency techniques → fetch detection rules for the top vulns: `/vulnetix:detection-rules <id>`
- For Initial Access / Execution tactics → `/vulnetix:soc-triage --severity critical`

## Memory update

Append `event: attack-mapping` with technique IDs to each touched vuln entry.
