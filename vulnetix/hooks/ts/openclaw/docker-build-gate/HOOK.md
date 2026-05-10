---
name: docker-build-gate
description: Pre-build informational scan on Dockerfile/Containerfile when `docker build`, `podman build`, or `buildah` is invoked
event: command
---

PreToolUse hook on Bash. Runs a quick `vulnetix containers` scan against the repo's Dockerfile and surfaces critical/high findings as a systemMessage. Never blocks the build.
