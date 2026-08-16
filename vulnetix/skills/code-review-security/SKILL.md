---
name: code-review-security
description: 'Unified pre-merge security review — SAST + SCA + secrets + container + IaC + license against the PR diff, dependency-add gate for new direct deps, optional `gh pr review` posting. Use when conducting a comprehensive security review of a feature branch, gating a merge on critical findings, or producing a structured review comment for the PR.'
argument-hint: "[--base origin/main] [--pr <number>]"
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
triggers:
  - "security review"
  - "review pr"
  - "review pull request"
  - "pre-merge"
chain:
  - sast-scan
  - secret-scan
  - verify-fix
outputBudget: medium
cooldown: per-session
---

# Vulnetix Code Review (Security) Skill

## Use when

- Pre-merge: comprehensive security gate on the PR diff.
- Post all the right checks (SAST + SCA + secrets + container + IaC + license) without invoking each one separately.
- Producing a unified PR review comment via `gh pr review`.
- CI gate: block merge if any subsystem reports critical/high findings.
- Pre-release: final security pass on the release branch.

## Don't use for

- Single-subsystem scan — use the specific skill (`/vulnetix:sast-scan`, etc.).
- Triage of existing memory state — use `/vulnetix:dashboard`.
- Multi-step orchestration with conflict resolution — use `@pr-security-reviewer` agent.

## Conventions

This skill follows `skills/_lib/contract.md`: the Vulnetix CLI is auto-installed by hooks, `.vulnetix/capabilities.yaml` is always present, every `vulnetix vdb` call is piped through a verified `jq` filter from `skills/_lib/jq/`, independent calls run in parallel as concurrent Bash tool calls, and trailing follow-ups are limited to one line. See the contract for output style, memory write rules, and cooldowns.

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

## Edge cases & gotchas

- Six subsystems run in parallel — pace by 1s between batches if rate-limited.
- `gh pr review` posting requires `binaries.gh: true` AND a valid `gh auth status`. Pass `--no-post` to dry-run.
- Scope defaults to PR diff (`gh pr diff --name-only`); without `--pr` it falls back to `git diff origin/main...HEAD`.
- Empty subsystem (e.g. no Dockerfile changed) is skipped — does not contribute to the verdict.
- Dep-add-guard runs only on NEWLY ADDED direct deps in the diff; existing deps are not re-checked here.
- Verdict APPROVE / REQUEST_CHANGES is a recommendation — the user still drives the actual `gh pr review --approve|--request-changes`.
