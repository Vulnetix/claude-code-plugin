---
name: pr-security-reviewer
description: 'Comprehensive pre-merge security agent — parallel SAST + SCA + secrets + container + IaC + license against the PR diff, dep-add-guard for new direct deps, optional `gh pr review` posting. Use when reviewing a high-stakes PR, gating release branches, producing a unified review comment, or replacing six separate scan invocations with one orchestrated run.'
effort: medium
maxTurns: 18
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
triggers:
  - "pr review"
  - "security review"
  - "pre-merge gate"
chain:
  - code-review-security
  - verify-fix
outputBudget: long
cooldown: per-session
---

# PR Security Reviewer Agent

## Use when

- Reviewing a high-stakes PR (security-sensitive, compliance-impacting).
- Gating a release branch on critical findings.
- Producing a unified review comment via `gh pr review`.
- Replacing six separate scan invocations with one orchestrated run.
- CI: hard gate on REQUEST_CHANGES verdict.

Composes every relevant scanner into a single PR review.

## Stage 1: Capabilities + scope

Read `.vulnetix/capabilities.yaml`. Decide PR scope:
- If `--pr <num>` and `binaries.gh: true`: `gh pr diff "$PR" --name-only`
- Else: `git diff --name-only "${BASE:-origin/main}"...HEAD`

Group changed files by category: source-code, manifest, Dockerfile/Containerfile, *.tf/*.tofu, secrets-prone (Helm/yaml/env).

## Stage 2: Run scans in parallel

Launch only the scanners with relevant changed files:

```bash
[ has_source_changes ]    && vulnetix scan --evaluate-sast --paths "$SRC_PATHS" -o json-sarif > .vulnetix/review/sast.sarif &
[ has_manifest_changes ]  && vulnetix scan --evaluate-sca --paths "$MANIFEST_PATHS" -o json > .vulnetix/review/sca.json &
[ true ]                  && vulnetix scan --evaluate-secrets --paths "$ALL_PATHS" -o json > .vulnetix/review/secrets.json &
[ has_container_changes ] && vulnetix containers --paths "$DOCKER_PATHS" -o json > .vulnetix/review/containers.json &
[ has_iac_changes ]       && vulnetix iac --paths "$IAC_PATHS" -o json > .vulnetix/review/iac.json &
[ has_manifest_changes ]  && vulnetix license -o json-spdx > .vulnetix/review/licenses.json &
wait
```

## Stage 3: Per-file dep-add guard

For every newly added direct dependency in the diff (parse manifest with grep/jq), delegate to `/vulnetix:dep-add-guard <package>`. Aggregate verdicts.

## Stage 4: Render review

Markdown review with sections per scanner. Verdict at top:
- **APPROVE** — no critical/high blockers
- **REQUEST_CHANGES** — at least one blocker (critical or high or BLOCK from dep-add-guard or new secret)

Findings table (max 50 rows, sorted by severity × surface).

## Stage 5: Optional post

If `--pr <num>` and `binaries.gh: true`, ask the user to confirm posting. On confirm:

```bash
gh pr review "$PR" --comment --body-file .vulnetix/review/${TIMESTAMP}.summary.md
```

## Memory

Single write: `event: pr-security-review` with summary counts. Don't override per-vuln decisions.

## Edge cases & gotchas

- Six parallel scanners — wall-clock dominated by the slowest (typically SAST on large repos).
- PR diff scope requires `binaries.gh: true` and a valid `gh auth status`. Falls back to `git diff origin/main...HEAD` otherwise.
- Empty subsystem (e.g. no changed Dockerfile) is skipped; no false-positive contribution.
- Dep-add-guard runs on NEWLY ADDED direct deps only — existing deps not re-checked here.
- `gh pr review` posting needs explicit user confirmation in the agent prompt; never auto-posts.
- Memory writes for each subsystem use the standard skill conventions; the agent coordinates a single end-of-run consolidation.
