---
name: verify-fix
description: Re-scan after applying a fix and gate on exploit-maturity + severity thresholds. Confirms the patched manifest no longer carries the targeted CVE.
argument-hint: <vuln-id>
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
---

# Vulnetix Fix Verification Skill

Run after `/vulnetix:fix` (or any manual remediation) to confirm the vulnerability is gone and no regressions appeared.

## Step 1: Load capabilities + memory

Read `.vulnetix/capabilities.yaml` and `.vulnetix/memory.yaml`. Find the entry for `$ARGUMENTS`. Capture: package, fixed_version, manifest path.

## Step 2: Pre-flight

```bash
# Ensure the manifest changed since last scan
git diff --name-only HEAD~5 -- "<manifest_path>" 2>/dev/null
```

If no recent change to the manifest, warn the user and proceed.

## Step 3: Run gated scan

```bash
vulnetix scan \
  --evaluate-sca \
  --severity high \
  --exploits weaponized \
  -o json
```

Capture exit code. Non-zero means a critical/high vuln with weaponized exploit signal still present.

## Step 4: Targeted recheck of the specific CVE

```bash
vulnetix vdb fixes "$ARGUMENTS" -o json
vulnetix vdb vuln "$ARGUMENTS" -o json
```

Cross-check: does the *new* installed version fall outside the affected range?

## Step 5: Render verdict

```
Fix verification: <PASS | FAIL>
Vuln: $ARGUMENTS
Package: <name>
Pre-fix version: <prev>
Post-fix version: <new>
Affected range: <range>
Within affected range now? <yes/no>
Scan gate (high+weaponized): <pass/fail>
Other regressions introduced: <count>  (list top 5 if any)
```

## Step 6: Update memory

- On PASS: set `status: fixed`, `decision.choice: fix-applied`, append `event: fix-verified`.
- On FAIL: keep `status: affected`, append `event: fix-verification-failed` with reason.

## Step 7: Follow-ups on FAIL

- Suggest `/vulnetix:dep-resolve` if version bump is blocked by a transitive constraint.
- Suggest `/vulnetix:safe-harbor-resolver` (agent) if multiple manifests conflict.
