---
name: terraform-apply-gate
description: Pre-apply informational IaC scan when `terraform apply` or `tofu apply` is invoked
event: command
---

PreToolUse hook on Bash. Runs `vulnetix iac` against repo Terraform/OpenTofu files and surfaces critical/high findings before apply. Never blocks.
