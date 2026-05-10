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


# PreToolUse Bash gate — informational quick-check before npm/pip/cargo/etc.
# adds a dependency. Always exits 0; never blocks.

command -v jq &>/dev/null || exit 0
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -z "$COMMAND" ]] && exit 0

PACKAGE=""
ECO=""
if [[ "$COMMAND" =~ npm[[:space:]]+(i|install|add)[[:space:]]+([@a-zA-Z0-9_/.-]+) ]];   then PACKAGE="${BASH_REMATCH[2]}"; ECO="npm"; fi
if [[ "$COMMAND" =~ (pnpm|yarn)[[:space:]]+add[[:space:]]+([@a-zA-Z0-9_/.-]+) ]];        then PACKAGE="${BASH_REMATCH[2]}"; ECO="npm"; fi
if [[ "$COMMAND" =~ pip[[:space:]]+install[[:space:]]+([a-zA-Z0-9_.-]+) ]];              then PACKAGE="${BASH_REMATCH[1]}"; ECO="pypi"; fi
if [[ "$COMMAND" =~ uv[[:space:]]+add[[:space:]]+([a-zA-Z0-9_.-]+) ]];                   then PACKAGE="${BASH_REMATCH[1]}"; ECO="pypi"; fi
if [[ "$COMMAND" =~ cargo[[:space:]]+add[[:space:]]+([a-zA-Z0-9_-]+) ]];                 then PACKAGE="${BASH_REMATCH[1]}"; ECO="cargo"; fi
if [[ "$COMMAND" =~ go[[:space:]]+get[[:space:]]+([a-zA-Z0-9_./-]+) ]];                  then PACKAGE="${BASH_REMATCH[1]}"; ECO="go"; fi
if [[ "$COMMAND" =~ gem[[:space:]]+install[[:space:]]+([a-zA-Z0-9_.-]+) ]];              then PACKAGE="${BASH_REMATCH[1]}"; ECO="rubygems"; fi
if [[ "$COMMAND" =~ composer[[:space:]]+require[[:space:]]+([@a-zA-Z0-9_/.-]+) ]];       then PACKAGE="${BASH_REMATCH[1]}"; ECO="packagist"; fi

[[ -z "$PACKAGE" ]] && exit 0

# v1.4.0 cooldown: don't re-warn on the same package within a session.
if already_emitted "dep-install-gate:${PACKAGE}@${ECO}"; then exit 0; fi
record_emission "dep-install-gate:${PACKAGE}@${ECO}"

source "$(dirname "$0")/ensure-vulnetix-cli.sh"
ensure_vulnetix_cli || exit 0

# Quick vuln-count for the package
VULN_COUNT=$("$VULNETIX_CMD" vdb vulns "$PACKAGE" --limit 1 -o json 2>/dev/null | jq -r '.total // 0' 2>/dev/null)
MALWARE=$("$VULNETIX_CMD" vdb ai-malware list --package "$PACKAGE" --limit 1 -o json 2>/dev/null | jq -r '.results | length // 0' 2>/dev/null)

MSG="About to add ${PACKAGE} (${ECO}). Known vulns: ${VULN_COUNT:-0}"
if [[ "${MALWARE:-0}" -gt 0 ]]; then
    MSG="${MSG}. WARNING: matches an AI-malware family — investigate before installing. Run /vulnetix:dep-add-guard ${PACKAGE} for full risk assessment."
elif [[ "${VULN_COUNT:-0}" -gt 5 ]]; then
    MSG="${MSG}. Many known vulns — consider /vulnetix:dep-add-guard ${PACKAGE} before install."
fi

jq -n --arg m "Vulnetix: $MSG" '{systemMessage: $m}'
exit 0
