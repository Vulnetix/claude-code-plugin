# scorecard.jq — extract Pix-relevant fields from
# `vulnetix vdb scorecard <id> -V v2 -o json`.
#
# **Verification status: PARTIAL.** Inferred from v2_scorecard handler.
# Note: Vulnetix's `containers.adp[0].x_threatExposure` (returned by `vdb vuln`)
# already provides a composite score with rules; prefer that when both are available.

{
  id: (.cveId // .identifier // null),
  compositeScore: (.compositeScore // .score // null),
  factors: ([(.factors // [])[] | {
    name,
    weight,
    score
  }])
}
