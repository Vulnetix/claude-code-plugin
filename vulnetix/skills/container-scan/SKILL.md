---
name: container-scan
description: Analyze Dockerfiles, Containerfiles, and compose files. Optionally compose with Trivy / Grype / Syft when those binaries are present.
argument-hint: "[--paths Dockerfile1 Dockerfile2] [--image registry/img:tag]"
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
triggers:
  - "container scan"
  - "dockerfile"
  - "containerfile"
  - "scan image"
chain:
  - verify-fix
outputBudget: short
cooldown: per-session
---

# Vulnetix Container Scan Skill

## Conventions

This skill follows [`_lib/contract.md`](../_lib/contract.md): the Vulnetix CLI is auto-installed by hooks, `.vulnetix/capabilities.yaml` is always present, every `vulnetix vdb` call is piped through a verified `jq` filter from [`_lib/jq/`](../_lib/jq/), independent calls run in parallel as concurrent Bash tool calls, and trailing follow-ups are limited to one line. See the contract for output style, memory write rules, and cooldowns.

## Step 1: Load capabilities

Read `.vulnetix/capabilities.yaml`. Note: `binaries.{docker,podman,trivy,grype,syft}`, `repo.{dockerfile,containerfile,compose,docker_compose}`. If no container artifacts found AND no `--image` argument, abort with a one-liner.

## Step 2: Run Vulnetix container analysis

```bash
vulnetix containers --paths "$DOCKERFILE_PATHS" -o json > .vulnetix/containers.${TIMESTAMP}.json
```

Or:

```bash
vulnetix scan --enable-containers --paths "$DOCKERFILE_PATHS" -o json
```

Captures: base-image risk, EOL bases, exposed secrets, missing `USER`, root processes, missing healthchecks, vulnerable system packages.

## Step 3: Compose with installed scanners (conditional)

For each available binary:

- `binaries.trivy: true` →
  ```bash
  trivy config "$DOCKERFILE_PATH" --format json > .vulnetix/containers/trivy.config.json
  trivy image "$IMAGE" --format json > .vulnetix/containers/trivy.image.json   # if --image
  ```
- `binaries.grype: true` AND `--image` →
  ```bash
  grype "$IMAGE" -o json > .vulnetix/containers/grype.json
  ```
- `binaries.syft: true` AND `--image` →
  ```bash
  syft "$IMAGE" -o cyclonedx-json > .vulnetix/containers/${IMAGE//[\/:]/_}.cdx.json
  ```

Merge findings into a unified table; de-dup by CVE+package.

## Step 4: Render

```
| Severity | Source | Issue | File / Layer | Fix |
| Critical | trivy  | CVE-... in libxml2 2.9.10 | layer 3 | bump base to alpine:3.19 |
```

Plus a "Hardening checklist" section: USER directive, healthcheck, pinned versions, reduced layers.

## Memory update

Write `.vulnetix/containers/<timestamp>.summary.yaml` with finding counts by severity.
