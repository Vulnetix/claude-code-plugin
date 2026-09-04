---
name: dep-upgrade-orchestrator
description: 'End-to-end dependency upgrade across all manifests — detect capabilities, scan for vulnerable deps, plan fixes ranked by patch-vs-major bump risk, apply per-manifest, run package-manager install, verify each fix, loop on conflicts via dep-resolve. Use when running a quarterly upgrade pass, modernising a stale repo, or producing a "what would it take to upgrade everything safely" report.'
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

## Use when

- Quarterly upgrade pass across all dependencies.
- Modernising a stale repo with many version-lagged deps.
- Producing a "what would it take to upgrade safely" report.
- Pre-major-release: upgrade as much as is safe.
- Replacing N-many manual upgrade attempts with one orchestrated run.

Multi-step agent for "upgrade everything safely". Composes `vulnetix agent capabilities`, scan, fix, verify-fix, dep-resolve and dependency-choice into one workflow.

## Stage 1: Capabilities

Run `vulnetix agent capabilities --force`. Read `.vulnetix/capabilities.yaml`. If `derived.primary_package_manager == unknown`, ask the user which package manager to target.

## Stage 2: Inventory

```bash
vulnetix scan --evaluate-sca -o json --disable-memory > .vulnetix/upgrade/inventory.json
```

Parse the result into a queue: each item is `(package, current, fixed_version_target, severity, vuln_id)` for any package with a known fix.

## Stage 3: Plan upgrades

For each queue item, decide bump strategy:
- Patch-level fix → safe to bump (low risk)
- Minor-level → safe with confirmation
- Major-level → requires user confirmation (call `dependency-choice <package>` for the recommended target)

Group items by manifest file.

## Stage 4: Apply, verify, loop

For each manifest:

1. Run `fix <vuln-id>` (delegate, capture proposed change).
2. Apply the change.
3. Run `<package-manager> install` for that ecosystem.
4. If install fails (peer-dep / transitive conflict), run `dep-resolve <package>` and retry.
5. Run `verify-fix <vuln-id>`.
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
- Run `dep-resolve` for stuck items.
```

## Guidelines

- Never push or commit; the user reviews.
- Cap parallelism: at most one manifest at a time per package manager.
- Stop and ask the user if a major-version bump would be needed for an unfixable issue.

## Edge cases & gotchas

- Per-manifest sequential execution — one PM at a time to avoid concurrent lockfile writes.
- Major-version bumps require explicit user confirmation; minor/patch can auto-apply if `--auto-apply-patch` is set.
- On install failure, the agent invokes `dep-resolve <package>` and retries — up to 3 iterations per item before logging and continuing.
- Verify-fix runs per item with `--exploits weaponized --severity high`; failed verification leaves the entry as `affected` with a history note.
- Memory write coordination: `--disable-memory` on every inner call, single consolidated write at end with `event: dep-upgrade-orchestrator`.
- Final report includes a "stuck items" list with `@safe-harbor-resolver` recommendation for each.
