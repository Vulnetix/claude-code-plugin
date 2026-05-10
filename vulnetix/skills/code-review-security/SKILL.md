---
name: code-review-security
description: PR-style security review. Runs SAST, SCA, secrets, container, and IaC scans against the diff and produces a unified review report.
argument-hint: "[--base origin/main] [--pr <number>]"
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
---

# Vulnetix Code Review (Security) Skill

A complete pre-merge security gate. Composes SAST + SCA + secrets + container + IaC + license, scoped to the diff.

## Step 1: Load capabilities

Read `.vulnetix/capabilities.yaml`. Use `repo.*` flags to skip scanners that have nothing to scan (e.g. skip IaC if no `*.tf` present).

## Step 2: Decide diff scope

If `--pr <number>` and `binaries.gh: true`:

```bash
gh pr diff "$PR" --name-only > .vulnetix/review/changed-files.txt
```

Else default to `git diff --name-only "$BASE"...HEAD`.

## Step 3: Run scans (parallel)

```bash
PATHS=$(cat .vulnetix/review/changed-files.txt | tr '\n' ' ')

vulnetix scan \
  --evaluate-sast \
  --evaluate-secrets \
  --evaluate-sca \
  $( [[ "$has_iac" == "true" ]] && echo "--enable-iac" ) \
  $( [[ "$has_containers" == "true" ]] && echo "--enable-containers" ) \
  --paths "$PATHS" \
  -o json-sarif > .vulnetix/review/${TIMESTAMP}.sarif
```

Plus license check if direct deps changed:

```bash
vulnetix license -o json-spdx > .vulnetix/review/${TIMESTAMP}.licenses.spdx.json
```

## Step 4: Render unified review

Sections:
- **Summary**: counts by severity across all surfaces
- **Findings table** (max 50 rows, ordered by severity)
- **Suggested next actions** (per finding type)

If `--pr <number>` and `binaries.gh: true`, optionally post the review:

```bash
gh pr review "$PR" --comment --body-file .vulnetix/review/${TIMESTAMP}.summary.md
```

Pause for user confirmation before posting.

## Step 5: Verdict

```
Review verdict: APPROVE | REQUEST_CHANGES (N blockers)
```

Memory: append `event: code-review-security` with summary counts.
