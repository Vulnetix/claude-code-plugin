---
name: git-push-gate
description: 'PreToolUse Bash gate: detect `git push`; run secret-scan on the diff vs origin/HEAD and summarise open critical/high findings from `.vulnetix/memory.yaml`. One fire per session. Use when guarding push operations against secret leaks and open security issues.'
event: command
---

# Git-Push-Gate hook

## Use when

- A Bash command matches `git push`.
- The hook has not already fired this session.


PreToolUse hook on Bash. Runs `vulnetix secrets` against the diff vs. origin and reports high-confidence secret findings + count of open critical/high vulns from `.vulnetix/memory.yaml`. Never blocks.

## Edge cases & gotchas

- Diff is computed vs `origin/HEAD` or `main` (fallback HEAD~5) — for branches not yet pushed upstream, the diff may be empty.
- Secret scan is high-confidence only — low-confidence findings are dropped here (catch them with `/vulnetix:secret-scan`).
- Open-finding count uses a grep across memory.yaml for `severity:\s*(critical|high)` — accurate but does not filter by status (a fixed-but-unmarked vuln still counts).
- Force-push (`git push --force`) is matched; reset/restore commands are NOT.
- Cooldown per session — second push after fix is silent.
