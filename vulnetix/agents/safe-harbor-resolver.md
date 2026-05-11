---
name: safe-harbor-resolver
description: 'Multi-step dependency-conflict resolver for vulns where `/vulnetix:fix` fails — tries Strategy A (single bump retry), Strategy B (package-manager override), Strategy C (safe-harbour inline as first-party), Strategy D (workaround + detection-only mitigation). Use when an upgrade is blocked by peer-dep conflicts, the upstream maintainer has abandoned the package, or you need to weigh inline-vs-workaround trade-offs.'
effort: high
maxTurns: 18
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
triggers:
  - "resolve conflict"
  - "upgrade blocked"
  - "safe harbor"
chain:
  - dep-resolve
  - fix
  - verify-fix
outputBudget: long
cooldown: per-session
---

# Safe Harbor Resolver Agent

## Use when

- `/vulnetix:fix` failed because `<pm> install` errored on peer-deps.
- Upstream maintainer abandoned the package — need inline patching.
- Weighing inline-as-first-party (Type A0) vs workaround-only (Type C).
- Resolving a transitive vuln without bumping the parent direct dep.
- Last-resort before accepting risk on a CVE.

Last-resort agent for vulns where `/vulnetix:fix` fails because the lockfile won't resolve. Tries multiple strategies in order.

## Stage 1: Diagnose

Read `.vulnetix/memory.yaml` and find the target vuln. Capture: package, fixed_version, manifest, prior failure reason (history events).

Run package-manager-specific dep-tree:

```bash
case "$primary_package_manager" in
    npm)    npm ls "$PACKAGE" 2>&1 ;;
    pnpm)   pnpm why "$PACKAGE" ;;
    yarn)   yarn why "$PACKAGE" ;;
    pip|uv|poetry) pip show "$PACKAGE" ;;
    go)     go mod why "$PACKAGE" ;;
    cargo)  cargo tree -i "$PACKAGE" ;;
esac
```

## Stage 2: Strategy A — single bump (retry)

```bash
vulnetix vdb versions "$PACKAGE" -o json --disable-memory
vulnetix vdb fixes "$VULN_ID" -V v2 -o json --disable-memory
```

Try each candidate version against the constraints. If any resolve cleanly, attempt the bump and run `/vulnetix:verify-fix`.

## Stage 3: Strategy B — package-manager override

If Strategy A fails:

- npm: add `overrides` to package.json
- pnpm: add `pnpm.overrides` to package.json
- yarn: add `resolutions` to package.json
- pip: pin transitive in requirements.txt + `--no-deps` for the parent
- go: `replace` directive in go.mod
- cargo: `[patch]` section in Cargo.toml

Apply the override, run install, run `/vulnetix:verify-fix`.

## Stage 4: Strategy C — safe-harbour inline

If override fails or upstream maintainer abandoned the package:
- Delegate to `/vulnetix:fix` Type A0 (inline patched code as first-party).
- Surface license implications.
- Update memory with `decision.choice: inlined`.

## Stage 5: Strategy D — workaround only

If all above fail:
- Fetch detection rules: `/vulnetix:detection-rules $VULN_ID`
- Update memory with `decision.choice: mitigated` and link the rules.
- Mark as `risk-accepted` only with explicit user approval.

## Stage 6: Report

```
Safe-harbor resolution for $VULN_ID:
Strategy used: A | B | C | D
Outcome: <fixed | mitigated | risk-accepted>
Verification: <pass | fail>
Files changed: <list>
Memory decision: <choice>
```

## Edge cases & gotchas

- Strategy ordering A→B→C→D is intentional; A is least invasive (manifest-only), D is detection-only (no fix).
- Strategy A retry tries each candidate safe version against the constraints — can run 5-10 inner `vdb versions`+install attempts.
- Strategy B overrides have ecosystem-specific semantics: `npm overrides`, `pnpm.overrides`, `yarn resolutions`, `pip --no-deps + pin`, `go replace`, `cargo [patch]`.
- Strategy C inlines code from the upstream package — IMPORTS THE LICENSE TOO. Copy LICENSE / NOTICE / ATTRIBUTION files.
- Strategy D requires `derived.detection_stack` non-empty for detection-only mitigation to make sense; otherwise the agent surfaces the limitation.
- Memory write uses `decision.choice: inlined` for Strategy C — the closed-enum value. Custom strings break the dashboard.
