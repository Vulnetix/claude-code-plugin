#!/usr/bin/env bash
set -uo pipefail

# PreToolUse Bash gate — runs a quick IaC scan before terraform/tofu apply.
# Never blocks.

command -v jq &>/dev/null || exit 0
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -z "$COMMAND" ]] && exit 0

if [[ ! "$COMMAND" =~ (terraform|tofu)[[:space:]]+apply ]]; then
    exit 0
fi

# Only run if .tf files are present
if ! ls *.tf */*.tf 2>/dev/null | grep -q .; then
    exit 0
fi

source "$(dirname "$0")/ensure-vulnetix-cli.sh"
ensure_vulnetix_cli || exit 0

RESULT=$("$VULNETIX_CMD" iac -o json --silent 2>/dev/null)
[[ -z "$RESULT" ]] && exit 0

CRITICAL=$(echo "$RESULT" | jq -r '[.findings[]? | select(.severity=="critical")] | length // 0' 2>/dev/null)
HIGH=$(echo "$RESULT"     | jq -r '[.findings[]? | select(.severity=="high")] | length // 0' 2>/dev/null)

if [[ "${CRITICAL:-0}" -gt 0 ]] || [[ "${HIGH:-0}" -gt 0 ]]; then
    MSG="Vulnetix IaC pre-apply check: ${CRITICAL} critical, ${HIGH} high. Run /vulnetix:iac-scan for details."
    jq -n --arg m "$MSG" '{systemMessage: $m}'
fi

exit 0
