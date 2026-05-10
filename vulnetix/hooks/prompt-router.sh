#!/usr/bin/env bash
set -uo pipefail

# Prompt router — UserPromptSubmit hook.
# Detects keyword patterns in the user's prompt and injects a one-line
# suggestion pointing at the most relevant Vulnetix Pix skill. Silent
# unless a match is found. Emits at most one suggestion per prompt.

if ! command -v jq &>/dev/null; then
    exit 0
fi

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.user_prompt // .prompt // empty' 2>/dev/null)
[[ -z "$PROMPT" ]] && exit 0

# Lower-case for matching
P=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

emit() {
    local suggestion="$1"
    jq -n --arg msg "Vulnetix: $suggestion" '{systemMessage: $msg}'
    exit 0
}

# Highest specificity first.
if [[ "$P" =~ (zero[[:space:]\-]?day|in[[:space:]]the[[:space:]]wild|actively[[:space:]]exploit) ]]; then
    emit "Active-exploitation language detected. Consider \`/vulnetix:incident-respond <vuln-id>\` for the full SOC playbook."
fi

if [[ "$P" =~ (compliance|audit|sbom|attestation) ]]; then
    emit "Compliance keyword detected. \`/vulnetix:compliance-report\` builds the full bundle (SBOM+VEX+SARIF+licenses)."
fi

if [[ "$P" =~ (fix[[:space:]]+(cve|ghsa)|patch[[:space:]]+.*vuln) ]]; then
    emit "Use \`/vulnetix:fix <id>\` to apply, then \`/vulnetix:verify-fix <id>\` to confirm."
fi

if [[ "$P" =~ (triage|prioritize[[:space:]]+vuln|review.*security[[:space:]]+(queue|backlog)) ]]; then
    emit "Try \`/vulnetix:soc-triage\` for the prioritized SOC queue."
fi

if [[ "$P" =~ (review.*(pr|pull[[:space:]]request)|security[[:space:]]review) ]]; then
    emit "Try \`/vulnetix:code-review-security --pr <number>\` for a unified PR security review."
fi

if [[ "$P" =~ (terraform|tofu|cloudformation|iac|kubernetes[[:space:]]manifest) ]]; then
    emit "Run \`/vulnetix:iac-scan\` against changed IaC files."
fi

if [[ "$P" =~ (dockerfile|containerfile|build[[:space:]]image) ]]; then
    emit "Run \`/vulnetix:container-scan\` to assess the Dockerfile."
fi

if [[ "$P" =~ ((api|access)[[:space:]_-]?(key|token)|password|secret) ]]; then
    emit "Avoid hardcoding credentials. Run \`/vulnetix:secret-scan --staged-only\` before commit."
fi

if [[ "$P" =~ ((add|install|require|use)[[:space:]]+([a-z0-9_\@\-]+)[[:space:]]*(package|library|dep|dependency)?) ]]; then
    emit "About to add a dependency? \`/vulnetix:dep-add-guard <package>\` checks vuln/malware/license/EOL first."
fi

if [[ "$P" =~ (auth|crypto|sql[[:space:]]injection|xss|deserialize|deserialization) ]]; then
    emit "Writing security-sensitive code? \`/vulnetix:secure-code-write <topic>\` surfaces relevant rules and patterns."
fi

if [[ "$P" =~ (eol|end[[:space:]\-]of[[:space:]\-]life|outdated[[:space:]]runtime) ]]; then
    emit "Check EOL status with \`/vulnetix:eol-check\`."
fi

exit 0
