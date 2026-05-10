# remediation.jq — extract Pix-relevant fields from
# `vulnetix vdb remediation plan <id> -V v2 -o json`.
#
# **Verification status: PARTIAL.** V2 endpoint not captured during planning due to
# rate-limit budget. Field paths inferred from existing
# vulnetix/skills/remediation/SKILL.md and v2_remediation handler. Re-verify on
# first use; expand if the response carries fields not listed here.
#
# Retains the full action list (no top-N cap), full CWE guidance, full threat
# summary. The remediation plan is the authoritative how-to-fix output and
# should not be truncated.

{
  id: (.cveId // .identifier // null),
  status: (.status // null),
  confidence: (.confidence // null),
  actions: ([(.actions // .priorityActions // [])[] | {
    action: (.action // .description // null),
    priority: (.priority // null),
    packages: (.packages // .targets // []),
    verifyCommand: (.verifyCommand // .verify // null),
    verificationSteps: (.verificationSteps // []),
    confidence: (.confidence // null),
    rollback: (.rollback // null),
    notes: (.notes // null)
  }]),
  workarounds: ([(.workarounds // [])[] | {
    description: .description,
    effectiveness: (.effectiveness // null),
    sideEffects: (.sideEffects // null)
  }]),
  cweGuidance: (.cweGuidance // null),
  threatIntel: (.threatIntel // null),
  references: ((.references // [])[0:10])
}
