---
name: dockerfile-edit-gate
description: Background container scan after editing/writing a Dockerfile or Containerfile
event: message:preprocessed
---

PostToolUse hook on Edit/Write. Detects writes to Dockerfile/Containerfile/*.dockerfile and launches `vulnetix containers` in the background; results land in /tmp for `/vulnetix:container-scan` to consume.
