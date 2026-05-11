---
name: terraform-apply-gate
description: 'PreToolUse Bash gate: detect `terraform/tofu apply`; run a quick `vulnetix iac` scan and surface critical/high findings before infra changes. One fire per session. Use when guarding casual `terraform apply` invocations without blocking.'
event: command
---

# Terraform-Apply-Gate hook

## Use when

- A Bash command matches an apply pattern.
- `*.tf` files exist in cwd.
- The hook has not already fired this session.


PreToolUse hook on Bash. Runs `vulnetix iac` against repo Terraform/OpenTofu files and surfaces critical/high findings before apply. Never blocks.

## Edge cases & gotchas

- Hook does not run `terraform plan` — too risky (state access). It runs static analysis on `*.tf` files only.
- Provider-specific rules are detected via resource type prefix; non-standard provider names may slip through.
- Cooldown per session — second apply after editing IaC is silent.
- Exit 0 always; never blocks the apply.
- OpenTofu (`tofu apply`) and Terraform (`terraform apply`) are both matched.
