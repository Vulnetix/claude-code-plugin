---
title: Hooks
weight: 3
description: Event-driven hooks that scan, track, and surface vulnerability intelligence automatically. Includes capability detection, dependency-add gating, container/IaC pre-checks, and prompt routing.
---

The Vulnetix plugin registers a set of hooks with Claude Code (and equivalents for Augment, CodeBuddy, Codex, Copilot, Cortex, Cursor, Gemini, iFlow, Kiro, OpenHands, Qoder, Qwen, Windsurf, Amazon Q). Each hook fires on a specific event, performs lightweight analysis, and injects an informational `systemMessage` back into the conversation. Hooks never block operations -- they always exit 0.

## Hook overview

| Hook | Event | Matcher | Timeout | Purpose |
|------|-------|---------|---------|---------|
| [Capabilities Detect](capabilities-detect) | SessionStart | -- | 15s | Probes binaries + repo signals; writes `.vulnetix/capabilities.yaml` |
| [Session Summary](session-summary) | SessionStart | -- | 10s | Displays vulnerability dashboard on session start |
| [Pre-Commit Scan](pre-commit-scan) | PreToolUse | Bash | 30s | Extracts packages from staged manifests and runs background VDB searches |
| [Dep Install Gate](dep-install-gate) | PreToolUse | Bash | 20s | Quick vuln/malware check before npm/pip/cargo/etc. install |
| [Docker Build Gate](docker-build-gate) | PreToolUse | Bash | 30s | Quick container scan before docker/podman build |
| [Terraform Apply Gate](terraform-apply-gate) | PreToolUse | Bash | 30s | Quick IaC scan before terraform/tofu apply |
| [Git Push Gate](git-push-gate) | PreToolUse | Bash | 30s | Pre-push secret-scan + open-finding summary |
| [Manifest Edit Gate](manifest-edit-scan) | PreToolUse | Edit\|Write | 30s | Checks packages being added/modified for risk |
| [Post-Install Scan](post-install-scan) | PostToolUse | Bash | 120s | Scans after dependency install commands |
| [Dockerfile Edit Gate](dockerfile-edit-gate) | PostToolUse | Edit\|Write | 10s | Background container scan after Dockerfile edits |
| [IaC Edit Gate](iac-edit-gate) | PostToolUse | Edit\|Write | 10s | Background IaC scan after `*.tf`/`*.tofu` edits |
| [Stop Reminder](stop-reminder) | Stop | -- | 10s | Reminds about unresolved vulnerabilities |
| [Context Inject](vuln-context-inject) | UserPromptSubmit | -- | 15s | Auto-detects CVE/GHSA IDs in messages |
| [Prompt Router](prompt-router) | UserPromptSubmit | -- | 10s | Routes security-relevant prompts to the matching skill |

## Key principles

**Never blocks.** Every hook exits 0 regardless of what it finds. Hooks are informational -- they surface context and suggest actions but never prevent commits, edits, or other operations.

**JSON systemMessage output.** All hooks communicate by writing a JSON object to stdout:

```json
{"systemMessage": "Vulnetix: ..."}
```

Claude Code reads this and injects it into the conversation context, making the information available to the AI without interrupting the developer.

**Minimal dependencies.** Hooks require only two external tools:

- **jq** -- for JSON processing (manifest parsing, API response handling, systemMessage construction)
- **vulnetix CLI** -- authenticated with a Vulnetix account for API access

If either dependency is missing, hooks exit silently rather than producing errors.

**Data directory.** Hooks that generate artifacts (package search results, SBOMs, memory updates) write to `.vulnetix/` in the project root. This directory is automatically added to `.gitignore` on first use.

## How hooks are registered

Hooks are declared in the plugin's `hooks.json` file and registered with Claude Code when the plugin is installed. Each entry specifies:

- **hook** -- the Claude Code event name (e.g., `PreToolUse`, `PostToolUse`)
- **matcher** -- optional tool name filter (e.g., `Bash`, `Edit|Write`)
- **script** -- path to the shell script
- **timeout** -- maximum execution time in seconds

## Agent-specific configuration

The same six hooks work across multiple agents. Each agent uses its own config file format — the plugin ships a pre-built config for each:

| Agent | Config file | Notes |
|-------|------------|-------|
| Claude Code | `hooks.json` | Default |
| Augment | `hooks.augment.json` | |
| CodeBuddy | `hooks.codebuddy.json` | Regex matchers |
| Cortex Code | `hooks.cortex.json` | |
| iFlow CLI | `hooks.iflow.json` | |
| OpenHands | `hooks.openhands.json` | PreToolUse + PostToolUse only |
| Qoder | `hooks.qoder.json` | |
| Qwen Code | `hooks.qwen.json` | Timeouts in milliseconds |

Hooks are registered automatically when you install via `npx skills add`.
