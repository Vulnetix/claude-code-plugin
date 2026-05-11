---
name: prompt-router
description: 'UserPromptSubmit hook: scan the prompt for trigger phrases declared in every SKILL.md frontmatter and emit at most one suggestion per skill per session. Use when matching natural-language intent ("triage these vulns") to the right slash-command without forcing the LLM to memorise 32 commands.'
event: message:received
---

# Prompt-Router hook

## Use when

- Every user prompt — the hook runs silently.
- Trigger cache (24h TTL) is missing or stale.


Single UserPromptSubmit hook that scans the user's prompt for keyword patterns (dependency-add, fix/patch CVE, triage, PR review, IaC, Dockerfile, secrets, EOL, secure-coding topics, compliance, incident response) and emits at most one short suggestion pointing at the matching skill. Silent unless a pattern matches.

## Edge cases & gotchas

- First-prompt cost: builds the trigger cache by parsing every SKILL.md frontmatter. Subsequent prompts are O(triggers).
- Per-skill cooldown via `_lib/cooldown.sh` — keyed on `router:<skill-name>` plus session PPID.
- Match is substring (case-insensitive); over-broad triggers can shadow more-specific ones. First match wins.
- No-op on missing `jq` or missing `triggers:` arrays — silent.
- Suggestion text references the SKILL.md path; ensure path stability if the skills are moved.
