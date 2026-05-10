---
name: safe-harbor-resolver
description: Resolve dependency-version conflicts blocking a fix. Tries override → safe-harbour inline → workaround paths. End-to-end remediation when a simple bump fails.
effort: high
maxTurns: 18
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
---

# Safe Harbor Resolver Agent

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
