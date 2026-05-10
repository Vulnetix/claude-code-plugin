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


# PreToolUse Bash gate — runs a quick Vulnetix container scan against the
# repo's Dockerfile(s) before docker/podman build. Never blocks.

command -v jq &>/dev/null || exit 0
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -z "$COMMAND" ]] && exit 0

if [[ ! "$COMMAND" =~ (docker|podman|buildah)[[:space:]]+build ]]; then
    exit 0
fi

# Only run if a Dockerfile/Containerfile is present
DOCKERFILE=$(ls Dockerfile Containerfile 2>/dev/null | head -1)
[[ -z "$DOCKERFILE" ]] && exit 0


# v1.4.0 cooldown: emit at most once per session for this hook.
if already_emitted "docker-build-gate"; then exit 0; fi
record_emission "docker-build-gate"
source "$(dirname "$0")/ensure-vulnetix-cli.sh"
ensure_vulnetix_cli || exit 0

RESULT=$("$VULNETIX_CMD" containers --paths "$DOCKERFILE" -o json --silent 2>/dev/null)
[[ -z "$RESULT" ]] && exit 0

CRITICAL=$(echo "$RESULT" | jq -r '[.findings[]? | select(.severity=="critical")] | length // 0' 2>/dev/null)
HIGH=$(echo "$RESULT"     | jq -r '[.findings[]? | select(.severity=="high")] | length // 0' 2>/dev/null)

if [[ "${CRITICAL:-0}" -gt 0 ]] || [[ "${HIGH:-0}" -gt 0 ]]; then
    MSG="Vulnetix container pre-build check on ${DOCKERFILE}: ${CRITICAL} critical, ${HIGH} high. Run /vulnetix:container-scan for details."
    jq -n --arg m "$MSG" '{systemMessage: $m}'
fi

exit 0
