# scorecard.jq — extract Pix-relevant fields from
# `vulnetix vdb scorecard <id> -V v2 -o json`.
#
# **Verification status: PARTIAL.** Inferred from v2_scorecard handler.
# Note: Vulnetix's `containers.adp[0].x_threatExposure` (returned by `vdb vuln`)
# already provides a composite score with rules; prefer that when both are
# available. Retains the full factor breakdown and all narrative fields.

{
  id: (.cveId // .identifier // null),
  compositeScore: (.compositeScore // .score // null),
  level: (.level // null),
  reasoning: (.reasoning // null),
  factors: ([(.factors // [])[] | {
    name: .name,
    weight: .weight,
    score: .score,
    reason: (.reason // null),
    contribution: (.contribution // null)
  }]),
  recommendations: (.recommendations // [])
}
