#!/usr/bin/env bash
set -uo pipefail

# Prompt router — UserPromptSubmit hook (v1.4.0).
# Reads `triggers:` lists from each SKILL.md frontmatter (cached for 24h in
# /tmp/vulnetix-trigger-cache.txt), matches the user's prompt against them,
# and emits at most one suggestion per session per skill via _lib/cooldown.sh.
# Always exits 0; never blocks.

if ! command -v jq &>/dev/null; then
    exit 0
fi

# Source the cooldown helper. Falls back to no-op if missing.
COOLDOWN_LIB="$(dirname "$0")/_lib/cooldown.sh"
if [[ -f "$COOLDOWN_LIB" ]]; then
    # shellcheck disable=SC1090
    source "$COOLDOWN_LIB"
else
    already_emitted() { return 1; }
    record_emission() { :; }
fi

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.user_prompt // .prompt // empty' 2>/dev/null)
[[ -z "$PROMPT" ]] && exit 0
PROMPT_LC=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# --- Build trigger cache (skill-name<TAB>trigger-phrase per line) ---

CACHE_FILE="/tmp/vulnetix-trigger-cache.txt"
SKILLS_DIR="$(dirname "$0")/../skills"

# Refresh cache if missing or older than 24h
if [[ ! -f "$CACHE_FILE" ]] || [[ -n "$(find "$CACHE_FILE" -mmin +1440 2>/dev/null)" ]]; then
    : > "$CACHE_FILE"
    for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
        [[ -f "$skill_md" ]] || continue
        # Extract skill name and triggers from YAML frontmatter (between the first two `---`)
        name=$(awk '/^---$/{c++; next} c==1 && /^name:/{sub(/^name: */, ""); print; exit}' "$skill_md")
        [[ -z "$name" ]] && continue
        # Extract trigger phrases under `triggers:` block
        awk -v n="$name" '
            /^---$/{c++; next}
            c==1 && /^triggers:/{intriggers=1; next}
            c==1 && intriggers && /^  - /{
                phrase=$0; sub(/^  - "?/, "", phrase); sub(/"?$/, "", phrase)
                if (length(phrase) > 0) print n "\t" phrase
                next
            }
            c==1 && intriggers && /^[a-z_-]+:/{intriggers=0}
        ' "$skill_md" >> "$CACHE_FILE"
    done
fi

[[ ! -s "$CACHE_FILE" ]] && exit 0

# --- Match prompt against triggers ---
# Find the first matching skill that hasn't been suggested this session.

while IFS=$'\t' read -r skill_name phrase; do
    [[ -z "$skill_name" ]] && continue
    [[ -z "$phrase" ]] && continue
    phrase_lc=$(echo "$phrase" | tr '[:upper:]' '[:lower:]')
    if [[ "$PROMPT_LC" == *"$phrase_lc"* ]]; then
        if ! already_emitted "router:${skill_name}"; then
            record_emission "router:${skill_name}"
            jq -n \
                --arg msg "Vulnetix: \`/vulnetix:${skill_name}\` matches this request — see \`vulnetix/skills/${skill_name}/SKILL.md\`." \
                '{systemMessage: $msg}'
            exit 0
        fi
    fi
done < "$CACHE_FILE"

exit 0
