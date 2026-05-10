# workarounds.jq — extract Pix-relevant fields from
# `vulnetix vdb workarounds <id> -V v2 -o json`.
#
# **Verification status: PARTIAL.** Re-verify on first use; some workaround entries
# are stored inside `vdb fixes`.fixes.workarounds[] rather than at this dedicated
# endpoint, so this filter may need to fall back to extracting from the fixes
# response.
#
# Retains the full text of each workaround — these are the operational
# instructions the operator must follow exactly; do not truncate.

{
  id: (.cveId // .identifier // null),
  count: ((.workarounds // []) | length),
  workarounds: ([(.workarounds // [])[] | {
    text: (.text // .description // null),
    effectiveness: (.effectiveness // null),
    sideEffects: (.sideEffects // null),
    applicability: (.applicability // null),
    source: (.source // null),
    references: (.references // [])
  }])
}
