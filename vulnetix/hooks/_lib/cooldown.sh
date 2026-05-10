#!/usr/bin/env bash
# cooldown.sh — per-session emission gate for hooks and skill suggestions.
#
# Usage (from a hook script):
#
#   source "$(dirname "$0")/_lib/cooldown.sh"
#   already_emitted "dep-add-guard:lodash@4.17.20" && exit 0
#   record_emission "dep-add-guard:lodash@4.17.20"
#   <emit suggestion>
#
# Markers live in /tmp/vulnetix-cd-${PPID}.txt. The PPID anchor scopes them
# to the current shell session — a fresh terminal / agent restart resets them.
# Override the anchor by setting VULNETIX_COOLDOWN_KEY in the environment.

_vlx_cooldown_file() {
    local anchor="${VULNETIX_COOLDOWN_KEY:-$PPID}"
    echo "/tmp/vulnetix-cd-${anchor}.txt"
}

# Returns 0 if the key has been recorded this session, 1 otherwise.
already_emitted() {
    local key="$1"
    local file
    file=$(_vlx_cooldown_file)
    [[ -f "$file" ]] && grep -Fxq "$key" "$file"
}

# Record a key in the session cooldown file. Idempotent.
record_emission() {
    local key="$1"
    local file
    file=$(_vlx_cooldown_file)
    if ! already_emitted "$key"; then
        echo "$key" >> "$file"
    fi
}

# Convenience: emit-once-per-session wrapper. Echoes $msg as a JSON systemMessage
# only on first call for the given key. Subsequent calls in the same session no-op.
emit_once() {
    local key="$1"; shift
    local msg="$*"
    if ! already_emitted "$key"; then
        record_emission "$key"
        if command -v jq &>/dev/null; then
            jq -n --arg m "$msg" '{systemMessage: $m}'
        else
            printf '{"systemMessage": "%s"}\n' "${msg//\"/\\\"}"
        fi
    fi
}
