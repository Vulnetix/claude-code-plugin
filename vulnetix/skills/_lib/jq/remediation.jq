# remediation.jq — extract Pix-relevant fields from
# `vulnetix vdb remediation plan <id> -V v2 -o json`.
#
# **Verification status: PARTIAL.** V2 endpoint not captured during planning due to
# rate-limit budget. Field paths inferred from existing
# /home/chris/GitHub/Vulnetix/pix-ai-coding-assistant/vulnetix/skills/remediation/SKILL.md
# and the v2_remediation handler. Re-verify on first use.

{
  id: (.cveId // .identifier // null),
  actions: ([(.actions // .priorityActions // [])[0:5][] | {
    action: (.action // .description // null),
    packages: (.packages // .targets // []),
    verifyCommand: (.verifyCommand // .verify // null),
    confidence: (.confidence // null)
  }]),
  cweGuidance: (.cweGuidance // null),
  threatSummary: ((.threatIntel.summary // .threatSummary // "") | if length > 200 then .[:197] + "..." else . end)
}
