---
name: dep-upgrade-orchestrator
description: End-to-end dependency upgrade across all manifests — detects capabilities, scans for vulnerable packages, plans fixes, applies them, and verifies. Loops on conflicts via dep-resolve.
effort: high
maxTurns: 25
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
triggers:
  - "upgrade dependencies"
  - "upgrade everything"
  - "modernize deps"
chain:
  - fix
  - verify-fix
  - dep-resolve
outputBudget: long
cooldown: per-session
---

# Dependency Upgrade Orchestrator

Multi-step agent for "upgrade everything safely". Composes capabilities-detect, scan, fix, verify-fix, dep-resolve, and safe-version into one workflow.

## Stage 1: Capabilities

Run `${CLAUDE_PLUGIN_ROOT}/hooks/capabilities-detect.sh` (force refresh). Read `.vulnetix/capabilities.yaml`. If `derived.primary_package_manager == unknown`, ask the user which package manager to target.

## Stage 2: Inventory

```bash
vulnetix scan --evaluate-sca -o json --disable-memory > .vulnetix/upgrade/inventory.json
```

Parse the result into a queue: each item is `(package, current, fixed_version_target, severity, vuln_id)` for any package with a known fix.

## Stage 3: Plan upgrades

For each queue item, decide bump strategy:
- Patch-level fix → safe to bump (low risk)
- Minor-level → safe with confirmation
- Major-level → requires user confirmation (call `/vulnetix:safe-version <package>` for the recommended target)

Group items by manifest file.

## Stage 4: Apply, verify, loop

For each manifest:

1. Run `/vulnetix:fix <vuln-id>` (delegate, capture proposed change).
2. Apply the change.
3. Run `<package-manager> install` for that ecosystem.
4. If install fails (peer-dep / transitive conflict), run `/vulnetix:dep-resolve <package>` and retry.
5. Run `/vulnetix:verify-fix <vuln-id>`.
6. On PASS → update memory, mark queue item done. On FAIL → log and continue (don't block the whole run).

Memory writes are coordinated via `--disable-memory` on inner CLI calls, with a single consolidated write at end of stage.

## Stage 5: Final verification

```bash
vulnetix scan --evaluate-sca --severity high --exploits weaponized -o json
```

Report any remaining critical/high items that didn't get fixed.

## Stage 6: Report

```
Upgrade orchestration complete.
- Manifests processed: N
- Fixes applied: M (P critical, Q high, R medium)
- Conflicts resolved via dep-resolve: K
- Remaining critical/high: J
- Run `/vulnetix:safe-harbor-resolver` for stuck items.
```

## Guidelines

- Never push or commit; the user reviews.
- Cap parallelism: at most one manifest at a time per package manager.
- Stop and ask the user if a major-version bump would be needed for an unfixable issue.
