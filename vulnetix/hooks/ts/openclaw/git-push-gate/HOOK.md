---
name: git-push-gate
description: Pre-push informational secret-scan + open-finding summary when `git push` is invoked
event: command
---

PreToolUse hook on Bash. Runs `vulnetix secrets` against the diff vs. origin and reports high-confidence secret findings + count of open critical/high vulns from `.vulnetix/memory.yaml`. Never blocks.
