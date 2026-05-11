---
name: docker-build-gate
description: 'PreToolUse Bash gate: detect `docker/podman/buildah build`; run a quick `vulnetix containers` scan of the repo Dockerfile and surface critical/high findings. One fire per session via cooldown. Use when guarding casual `docker build .` invocations without blocking.'
event: command
---

# Docker-Build-Gate hook

## Use when

- A Bash command matches a build pattern.
- A Dockerfile or Containerfile exists in cwd.
- The hook has not already fired this session.


PreToolUse hook on Bash. Runs a quick `vulnetix containers` scan against the repo's Dockerfile and surfaces critical/high findings as a systemMessage. Never blocks the build.

## Edge cases & gotchas

- Only the repo-root Dockerfile is scanned; multi-stage builds with sub-Dockerfiles need explicit scoping.
- Hook scans BEFORE the build runs; the actual image is not scanned (use `/vulnetix:container-scan --image` after build).
- Cooldown is global per session — second Dockerfile edit + rebuild in the same session is silent.
- Exit 0 always; never blocks the build.
- Requires `binaries.docker` or `binaries.podman` to be in capabilities.yaml; otherwise silent skip.
