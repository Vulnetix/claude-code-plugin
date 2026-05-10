#!/usr/bin/env bash
set -uo pipefail
# Cooldown helpers — silent fallback if missing.
COOLDOWN_LIB="$(dirname "$0")/_lib/cooldown.sh"
if [[ -f "$COOLDOWN_LIB" ]]; then
    # shellcheck disable=SC1090
    source "$COOLDOWN_LIB"
else
    already_emitted() { return 1; }
    record_emission() { :; }
fi


# PreToolUse Bash gate — runs secret-scan + summarizes open critical findings
# before git push. Never blocks.

command -v jq &>/dev/null || exit 0
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -z "$COMMAND" ]] && exit 0

if [[ ! "$COMMAND" =~ git[[:space:]]+push ]]; then
    exit 0
fi


# v1.4.0 cooldown: emit at most once per session for this hook.
if already_emitted "git-push-gate"; then exit 0; fi
record_emission "git-push-gate"
source "$(dirname "$0")/ensure-vulnetix-cli.sh"
ensure_vulnetix_cli || exit 0

# Secret scan on changed files vs. origin/HEAD (or main)
BASE=$(git merge-base HEAD origin/HEAD 2>/dev/null || git merge-base HEAD main 2>/dev/null || echo "HEAD~5")
PATHS=$(git diff --name-only "$BASE"...HEAD 2>/dev/null | tr '\n' ' ')

SECRET_COUNT=0
if [[ -n "$PATHS" ]]; then
    SECRET_RESULT=$("$VULNETIX_CMD" secrets --paths $PATHS -o json --silent 2>/dev/null)
    SECRET_COUNT=$(echo "$SECRET_RESULT" | jq -r '[.findings[]? | select(.confidence=="high")] | length // 0' 2>/dev/null)
fi

# Open critical/high findings from memory.yaml
OPEN_HIGH=0
if [[ -f .vulnetix/memory.yaml ]]; then
    OPEN_HIGH=$(grep -c '^\s*severity:\s*\(critical\|high\)' .vulnetix/memory.yaml 2>/dev/null || echo 0)
fi

MSG="Vulnetix pre-push: ${SECRET_COUNT} high-confidence secrets in diff, ${OPEN_HIGH} open critical/high vulns in memory."
if [[ "${SECRET_COUNT:-0}" -gt 0 ]]; then
    MSG="${MSG} Resolve secrets before pushing — run /vulnetix:secret-scan."
fi

jq -n --arg m "$MSG" '{systemMessage: $m}'
exit 0
