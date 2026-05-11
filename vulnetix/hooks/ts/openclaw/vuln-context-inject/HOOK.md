---
name: vuln-context-inject
description: 'UserPromptSubmit hook: auto-detect CVE / GHSA / PYSEC IDs in the user prompt; inject prior triage status as systemMessage so the LLM sees memory state inline. Use when threading prior decisions into the current conversation without forcing the user to look them up.'
event: message:received
---

# Vuln-Context-Inject hook

## Use when

- A user prompt contains a CVE/GHSA/PYSEC identifier.
- The ID has a memory entry with a non-default status or decision.


Injects relevant CVE/GHSA vulnerability context into user prompts before they are processed by the agent.

## Edge cases & gotchas

- Regex matches common ID formats; obscure formats (HUNTR-, BDU:) may not be detected.
- VEX status maps to developer-friendly language: `fixed` → "Fixed", `affected` → "Vulnerable", `under_investigation` → "Investigating", `not_affected` → "Not affected".
- No cooldown — fires on every matching prompt. Could be noisy if the LLM repeats CVE IDs across turns.
- Silent if no memory entry exists for the ID — no injection.
- Multiple IDs in one prompt — all are injected; the LLM context may grow.
