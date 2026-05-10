---
name: incident-respond
description: End-to-end SOC playbook for a CVE actively in the wild — sightings, IOCs, detection rules, fix/remediation, and VEX publication in one workflow.
argument-hint: <vuln-id>
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
---

# Vulnetix Incident Response Skill

A focused playbook when a CVE is hot. Composes IOC pivot, detection rules, fix planning, and VEX in a single linear flow.

## Step 1: Load capabilities + memory

Read `.vulnetix/capabilities.yaml` and `.vulnetix/memory.yaml`. Capture detection_stack, soar, and any prior data on the vuln.

## Step 2: Confirm urgency

```bash
vulnetix vdb sightings "$ARGUMENTS" -o json
vulnetix vdb kev get "$ARGUMENTS" -o json 2>/dev/null
```

Decide: **active** (sightings within 30 days OR in KEV) → run all steps. **dormant** → suggest `/vulnetix:remediation` instead and exit.

## Step 3: Containment intel

```bash
vulnetix vdb iocs "$ARGUMENTS" -o json
vulnetix vdb attack-techniques "$ARGUMENTS" -o json
```

Surface top 5 IOCs and the ATT&CK technique chain.

## Step 4: Detection deployment

If `derived.detection_stack` non-empty, fetch rules for each available family and write to `.vulnetix/detection/$ARGUMENTS/` (delegate to the same logic as `/vulnetix:detection-rules`, inline). Skip families absent from the stack.

## Step 5: Patch path

```bash
vulnetix vdb fixes "$ARGUMENTS" -V v2 -o json
vulnetix vdb remediation plan "$ARGUMENTS" -V v2 -o json
```

If a patch is available and the package is in this repo, suggest `/vulnetix:fix $ARGUMENTS` and offer to apply it inline (with user confirmation). If no patch, surface workarounds via `vdb workarounds $ARGUMENTS -V v2`.

## Step 6: VEX

Update memory with the chosen decision (`fix-applied`, `mitigated`, or `under_investigation`). Generate VEX:

```bash
vulnetix triage --provider vulnetix --vex-format openvex -o json > .vulnetix/vex/${ARGUMENTS}.${TIMESTAMP}.vex.json
```

## Step 7: Render incident report

```
Incident: $ARGUMENTS
Status: active | dormant
First sighting: <date>   Sources: <count>
KEV: <yes/no, deadline if any>
ATT&CK: <T-IDs>
Top IOCs: <ips/asns>
Detection rules deployed: <families and counts>
Patch available: <yes/no>
Repo affected: <yes/no, packages>
Decision: <choice>
VEX: <path>
Next:
- /vulnetix:verify-fix <id>
- /vulnetix:vex-publish --upload
```

## Memory update

Append `event: incident-respond` with stage outcomes to the vuln entry. Single consolidated write.
