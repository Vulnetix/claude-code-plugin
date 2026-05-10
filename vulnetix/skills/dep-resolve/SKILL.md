---
name: dep-resolve
description: Resolve dependency-version conflicts that block a fix. Finds a compatible safe version set across the dep graph.
argument-hint: <package-name> [--target-version X]
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
---

# Vulnetix Dependency Resolution Skill

When `/vulnetix:fix` proposes a version bump but the lockfile resolution fails (peer-dep conflict, transitive constraint, etc.), use this skill to find a compatible set.

## Step 1: Load capabilities + memory

Read `.vulnetix/capabilities.yaml` (`derived.primary_package_manager` decides which lockfile to read) and `.vulnetix/memory.yaml` (decisions / safe-harbour notes).

## Step 2: Map the conflict

```bash
# npm/pnpm/yarn
npm ls "$PACKAGE" 2>&1 || pnpm why "$PACKAGE" || yarn why "$PACKAGE"
# pip
pip show "$PACKAGE"
# go
go mod why "$PACKAGE"
# cargo
cargo tree -i "$PACKAGE"
```

Pick the command for the detected package manager. Capture the dep tree paths.

## Step 3: Pull safe-version graph

```bash
vulnetix vdb versions "$PACKAGE" -o json
vulnetix vdb fixes "$PACKAGE" -o json
```

For each candidate target version:
- Cross-check transitive constraints from Step 2
- Cross-check known vulns at that version (`vdb vulns`)

## Step 4: Propose resolution

Prefer (in order):
1. **Single bump** — newest patch version that fixes the vuln and satisfies constraints
2. **Override** — package-manager override (npm `overrides`, pnpm `pnpm.overrides`, yarn `resolutions`)
3. **Safe-harbour inline** — copy upstream patch into repo as first-party code (link to `/vulnetix:fix` Type A0 path)
4. **Workaround only** — `/vulnetix:detection-rules <vuln-id>` while waiting for upstream

## Step 5: Apply (with confirmation)

For option 1: edit the manifest, run `<pm> install` (npm/pnpm/yarn/pip/go/cargo).
For option 2: write the override block, run install.
For option 3: hand off to `/vulnetix:fix` Type A0.
For option 4: hand off to `/vulnetix:detection-rules`.

Always pause for user approval before writing manifest edits.

## Step 6: Verify

Suggest `/vulnetix:verify-fix <vuln-id>` after the resolution lands.

## Memory update

`event: dep-resolve` with the chosen path.
