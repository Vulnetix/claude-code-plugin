---
title: Docker Build Gate
weight: 50
description: Quick container scan of the Dockerfile before docker/podman build.
---

Quick container scan of the Dockerfile before docker/podman build.

## Trigger

PreToolUse on Bash

## Behavior

See [`hooks/docker-build-gate.sh`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/hooks/docker-build-gate.sh) and [`hooks/ts/openclaw/docker-build-gate/HOOK.md`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/hooks/ts/openclaw/docker-build-gate/HOOK.md). The hook reads `.vulnetix/capabilities.yaml` and skips work when the relevant binaries / repo signals are absent. Always exits 0; never blocks.

## See also

- [Capabilities YAML schema](/docs/data-structures/capabilities-yaml)
- [Hooks index](/docs/hooks/)
