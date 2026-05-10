---
name: sast-scan
description: Run Vulnetix SAST against changed files (or whole repo). Cross-references local Semgrep rules when present.
argument-hint: "[--rule-id ID] [--paths file1 file2] [--baseline]"
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
---

# Vulnetix SAST Skill

Static analysis on source code. Capability-aware: optionally augmented with the user's own Semgrep rules.

## Step 1: Load capabilities

Read `.vulnetix/capabilities.yaml`. Note `binaries.semgrep`, `repo.semgrep_config`.

## Step 2: Decide scope

If `--paths` given → scan those paths. Else scan files changed since `git merge-base origin/main HEAD` (or whole repo if not a git repo).

## Step 3: Run scan

```bash
vulnetix sast --paths "$PATHS" -o json-sarif > .vulnetix/sast.${TIMESTAMP}.sarif
```

If `--rule-id` provided, pass through.
If `--baseline`, also run `vulnetix scan --evaluate-sast --list-default-rules -o json` to record the rule set used.

## Step 4: Augment with local Semgrep (conditional)

If `binaries.semgrep: true` AND `repo.semgrep_config: true`:

```bash
semgrep --config .semgrep --json --quiet "$PATHS" > .vulnetix/sast.semgrep.${TIMESTAMP}.json
```

Merge findings into the SARIF report (de-duped by file:line:rule).

## Step 5: Render

| Severity | Rule | File:Line | Message | Source |

Group by severity (critical → low). Suggest `/vulnetix:secure-code-write` for repeated rule violations.

## Memory update

If running on a PR / branch, write a `.vulnetix/sast/<branch>.summary.yaml` with finding counts so `/vulnetix:code-review-security` can pick it up.
