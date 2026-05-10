---
name: prompt-router
description: Route security-relevant user prompts to the most appropriate Vulnetix Pix skill via a one-line systemMessage suggestion
event: message:received
---

Single UserPromptSubmit hook that scans the user's prompt for keyword patterns (dependency-add, fix/patch CVE, triage, PR review, IaC, Dockerfile, secrets, EOL, secure-coding topics, compliance, incident response) and emits at most one short suggestion pointing at the matching skill. Silent unless a pattern matches.
