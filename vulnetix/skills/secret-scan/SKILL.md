---
name: secret-scan
description: Detect hardcoded secrets (API keys, tokens, credentials) in repo. Pre-commit and on-demand.
argument-hint: "[--paths file1 file2] [--staged-only]"
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
---

# Vulnetix Secret Scan Skill

## Step 1: Load capabilities

Read `.vulnetix/capabilities.yaml`. Note `binaries.git` (required for `--staged-only`).

## Step 2: Decide scope

- `--staged-only`: `git diff --cached --name-only` for the file list.
- `--paths`: explicit list.
- Default: changed files vs. main branch, fallback to whole repo.

## Step 3: Run scan

```bash
vulnetix secrets --paths "$PATHS" -o json > .vulnetix/secrets.${TIMESTAMP}.json
```

Or via integrated scan:

```bash
vulnetix scan --evaluate-secrets --paths "$PATHS" -o json
```

## Step 4: Render

```
Secret findings: N (high-confidence: M)

| Type | File:Line | Snippet (redacted) | Confidence |
```

For each finding, emit a redacted snippet (replace 60% of the secret with `*`). Never print the full secret.

## Step 5: Remediation guidance

For each unique secret type, surface the standard rotation/revocation steps (AWS, GCP, GitHub PAT, Slack, Stripe, etc.). Do not auto-rotate.

If a secret is found in a committed file (not just staged):
- Suggest `git filter-repo` or BFG repo-cleaner
- Strongly recommend rotating the credential since it's in git history

## Memory update

Append a sanitized record to `.vulnetix/secrets/${TIMESTAMP}.summary.yaml` (counts by type, file paths, no values).
