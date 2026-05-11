---
name: incident-responder
description: 'Full SOC playbook agent for an actively exploited CVE — parallel sightings + KEV + IOCs + ATT&CK + fixes + remediation pull, capability-aware detection-rule deployment, optional patch path with verify-fix, VEX attestation publication. Use when a CVE goes hot, a vendor advisory names your dependency, or sightings spike on a tracked vuln.'
effort: high
maxTurns: 20
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
triggers:
  - "incident response"
  - "cve in the wild"
  - "actively exploited"
chain:
  - detection-rules
  - verify-fix
  - vex-publish
outputBudget: long
cooldown: per-session
---

# Incident Responder Agent

## Use when

- A CVE went hot overnight and you need a complete SOC response in one conversation.
- A vendor advisory names a dependency you ship.
- Active sightings spiked (CrowdSec, Shadowserver) on a tracked vuln.
- Coordinating detection deployment + patch + VEX in one workflow.
- Producing a post-incident timeline of "what we knew when".

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

## Edge cases & gotchas

- Stage 1 hits 6 parallel endpoints — rate-limit retries delay the batch on community auth. Use `--silent` to suppress retry chatter.
- Active classification = KEV-listed OR sightings within 30d OR EPSS > 0.5. Dormant CVEs bail out with a recommendation to use `/vulnetix:remediation`.
- Detection-rule writes are gated by `derived.detection_stack` — empty stack means no rule files; review capabilities before invoking.
- V2 endpoint quirks: `vdb workarounds <id> -V v2` and `vdb remediation plan <id> -V v2` carry partial data in some environments.
- VEX is generated with `under_investigation` as the default status until the user makes a decision. Pass `--final-only` for decided-only output.
- Memory write is single-consolidated at end with `event: incident-respond`; do NOT run concurrent invocations from the same session.
