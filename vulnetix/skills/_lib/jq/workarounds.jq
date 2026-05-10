# workarounds.jq — extract Pix-relevant fields from
# `vulnetix vdb workarounds <id> -V v2 -o json`.
#
# **Verification status: PARTIAL.** Re-verify on first use; some workaround entries
# are stored inside `vdb fixes`.fixes.workarounds[] rather than at this dedicated
# endpoint, so this filter may need to fall back to extracting from the fixes
# response.

{
  id: (.cveId // .identifier // null),
  count: ((.workarounds // []) | length),
  workarounds: ([(.workarounds // [])[] | {
    text: ((.text // .description // "") | if length > 200 then .[:197] + "..." else . end),
    effectiveness: (.effectiveness // null),
    sideEffects: (.sideEffects // null),
    applicability: (.applicability // null)
  }])
}
