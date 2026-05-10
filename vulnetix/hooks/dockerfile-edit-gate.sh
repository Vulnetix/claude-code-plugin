#!/usr/bin/env bash
set -uo pipefail

# PostToolUse Edit/Write — quick container scan after editing Dockerfile / Containerfile.
# Never blocks.

command -v jq &>/dev/null || exit 0
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)
[[ -z "$FILE" ]] && exit 0

BN=$(basename "$FILE")
if [[ "$BN" != "Dockerfile" ]] && [[ "$BN" != "Containerfile" ]] && [[ ! "$BN" =~ \.dockerfile$ ]]; then
    exit 0
fi

source "$(dirname "$0")/ensure-vulnetix-cli.sh"
ensure_vulnetix_cli || exit 0

(
    "$VULNETIX_CMD" containers --paths "$FILE" -o json --silent 2>/dev/null > "/tmp/vulnetix-dockerfile-${BN}.json"
) </dev/null >/dev/null 2>&1 &
disown

jq -n --arg m "Vulnetix: scanning ${FILE} in background. Run /vulnetix:container-scan for results." '{systemMessage: $m}'
exit 0
