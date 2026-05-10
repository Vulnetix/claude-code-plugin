---
name: incident-responder
description: SOC playbook agent for an actively exploited CVE — sightings, IOCs, ATT&CK, detection rules, patch path, VEX. End-to-end with parallel intelligence pulls.
effort: high
maxTurns: 20
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
---

# Incident Responder Agent

Run when a CVE goes hot. Composes `/vulnetix:soc-triage`, `/vulnetix:ioc-pivot`, `/vulnetix:detection-rules`, `/vulnetix:verify-fix`, and `/vulnetix:vex-publish`.

## Stage 1: Confirm scope + capabilities

Read `.vulnetix/capabilities.yaml`. If session-old, force refresh. Load `.vulnetix/memory.yaml`.

Run in parallel (single message, multiple Bash calls):

```bash
vulnetix vdb sightings "$VULN_ID" -o json --disable-memory
vulnetix vdb kev get "$VULN_ID" -o json --disable-memory 2>/dev/null
vulnetix vdb iocs "$VULN_ID" -o json --disable-memory
vulnetix vdb attack-techniques "$VULN_ID" -o json --disable-memory
vulnetix vdb fixes "$VULN_ID" -V v2 -o json --disable-memory
vulnetix vdb remediation plan "$VULN_ID" -V v2 -o json --disable-memory
```

## Stage 2: Decide active vs dormant

Active if: KEV-listed OR sightings within 30 days OR EPSS > 0.5. Else dormant — recommend `/vulnetix:remediation` and exit.

## Stage 3: Containment intel

Render the IOCs + ATT&CK summary. Save STIX bundle to `.vulnetix/iocs/${VULN_ID}.stix.json` if `derived.soar == "stix"`.

## Stage 4: Detection deployment

For each family in `derived.detection_stack` (skip absent families):

```bash
vulnetix vdb snort-rules list --cve-id "$VULN_ID" --format rules > .vulnetix/detection/$VULN_ID/snort.rules
vulnetix vdb yara-rules list --cve-id "$VULN_ID" --format rules > .vulnetix/detection/$VULN_ID/vuln.yar
vulnetix vdb nuclei get "$VULN_ID" --format yaml > .vulnetix/detection/$VULN_ID/nuclei.yaml
```

## Stage 5: Patch path

If a fix exists AND the package is in this repo:
- Delegate to `/vulnetix:fix $VULN_ID`
- Then `/vulnetix:verify-fix $VULN_ID`

If no fix:
- Surface workarounds: `vulnetix vdb workarounds $VULN_ID -V v2 -o json`
- Suggest detection-only mitigation

## Stage 6: VEX

Append decision to memory and generate VEX:

```bash
vulnetix triage --provider vulnetix --vex-format openvex -o json > .vulnetix/vex/${VULN_ID}.${TIMESTAMP}.vex.json
```

Optionally upload via `/vulnetix:vex-publish --upload` (ask user).

## Stage 7: Report

Markdown incident report covering: status (active|dormant), IOC counts, ATT&CK chain, detection-rule deployment, patch verdict, VEX file path, suggested next steps.

## Memory coordination

All inner VDB calls use `--disable-memory`. Single consolidated write at the end with `event: incident-respond` plus stage outcomes.
