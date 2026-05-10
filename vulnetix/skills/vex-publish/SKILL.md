---
name: vex-publish
description: Generate VEX statements (OpenVEX / CycloneDX VEX) from triage decisions in memory.yaml and optionally upload to Vulnetix.
argument-hint: "[--format openvex|cyclonedx] [--upload]"
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
---

# Vulnetix VEX Publication Skill

Turns the decisions captured in `.vulnetix/memory.yaml` into a signed/uploadable VEX document.

## Step 1: Load memory

Read `.vulnetix/memory.yaml`. Collect every entry with a non-default `decision.choice` (i.e. anything that isn't `investigating`).

## Step 2: Map decisions → VEX status

Mapping (Vulnetix CLI uses the same):
- `not-affected` / `risk-avoided` → `not_affected`
- `fix-applied` → `fixed`
- `risk-accepted` / `deferred` / `mitigated` → `affected` (with mitigations)
- `investigating` → `under_investigation`

## Step 3: Generate VEX

```bash
vulnetix triage --provider vulnetix --vex-format ${FORMAT:-openvex} -o json > .vulnetix/vex/${TIMESTAMP}.vex.json
```

Default format `openvex`. If user passes `--format cyclonedx`, the CLI emits CycloneDX VEX.

## Step 4: Upload (conditional)

If user passed `--upload`:

```bash
vulnetix upload --file .vulnetix/vex/${TIMESTAMP}.vex.json
```

Otherwise, skip and report the local file path.

## Step 5: GitHub PR comment (conditional)

If `binaries.gh: true` and we're inside a PR (env `GITHUB_REF` or `gh pr view --json number`):

```bash
gh pr comment "$PR_NUMBER" --body-file .vulnetix/vex/${TIMESTAMP}.vex.summary.md
```

Where the summary file is a short Markdown rendering of the VEX (auto-generated from the JSON).

## Step 6: Render report

```
VEX statements: N
- not_affected: N
- fixed: N
- affected (with mitigations): N
- under_investigation: N
File: .vulnetix/vex/<timestamp>.vex.json
Uploaded: <yes|no>
PR comment: <yes|no>
```
