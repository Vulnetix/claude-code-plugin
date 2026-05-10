---
name: iac-edit-gate
description: Background IaC scan after editing/writing *.tf or *.tofu files
event: message:preprocessed
---

PostToolUse hook on Edit/Write. Detects writes to `.tf` / `.tofu` files and launches `vulnetix iac` in the background.
