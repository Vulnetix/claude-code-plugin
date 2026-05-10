---
name: iac-scan
description: Scan Terraform / OpenTofu / Nix / Kubernetes manifests for misconfigurations and compliance violations.
argument-hint: "[--paths file1 file2]"
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
---

# Vulnetix IaC Scan Skill

## Step 1: Load capabilities

Read `.vulnetix/capabilities.yaml`. Confirm `derived.has_iac: true` or `--paths` provided. Otherwise abort.

## Step 2: Run scan

```bash
vulnetix iac --paths "$PATHS" -o json > .vulnetix/iac.${TIMESTAMP}.json
```

Captures: open security groups, missing encryption, public S3/GCS, IAM wildcards, unpinned providers, secrets in plaintext, missing tags, unencrypted state backends.

## Step 3: Render

| Severity | File:Line | Resource | Issue | Recommendation |

Group by file. For each high-severity issue, include a 2-3 line code example of the fix.

## Step 4: Risk overlay

If `binaries.terraform: true` (or `tofu`), suggest:

```bash
terraform plan -no-color | head -200    # for context on what would change
```

Don't run `terraform apply` from the skill.

## Memory update

`.vulnetix/iac/<timestamp>.summary.yaml` with finding counts.
