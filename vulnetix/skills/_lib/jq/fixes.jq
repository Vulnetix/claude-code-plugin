# fixes.jq: extract Pix-relevant fields from `vulnetix vdb fixes <id> -o json`.
#
# Verified against: CVE-2021-44228 (87 KB raw → ~25 KB filtered, ~71% reduction).
# Top-level keys: _deprecated, _links, aiAnalysis, cweRemediations, exploitationMaturity,
# fixAvailability, fixes{configurations,distributions,registry,solutions,sourceCode,workarounds},
# identifier, kevRequiredAction, summary{distributionPatches,registryFixes,sourceFixes,
# vendorAdvisories,workarounds}, timeline{datePublished,firstPatchDate,lifecycleStage,
# timeToPatchDays}, vendorComments.
#
# Retains: full summary, timeline, exploitationMaturity, kevRequiredAction (no
# truncation, since KEV actions are short enough), aiAnalysis when present, full
# cweRemediations array, and up to 30 entries per fix-type with all their fields.

{
  id: .identifier,
  fixAvailability: .fixAvailability,
  summary: .summary,
  timeline: .timeline,
  aiAnalysis: .aiAnalysis,
  exploitationMaturity: .exploitationMaturity,
  kevRequiredAction: .kevRequiredAction,
  cweRemediations: (.cweRemediations // []),
  fixCounts: {
    registry: ((.fixes.registry // []) | length),
    distributions: ((.fixes.distributions // []) | length),
    sourceCode: ((.fixes.sourceCode // []) | length),
    solutions: ((.fixes.solutions // []) | length),
    workarounds: ((.fixes.workarounds // []) | length),
    configurations: ((.fixes.configurations // []) | length)
  },
  fixes: {
    registry: ((.fixes.registry // [])[0:30]),
    distributions: ((.fixes.distributions // [])[0:30]),
    sourceCode: ((.fixes.sourceCode // [])[0:30]),
    solutions: ((.fixes.solutions // [])[0:30]),
    workarounds: ((.fixes.workarounds // [])[0:30]),
    configurations: ((.fixes.configurations // [])[0:30])
  },
  vendorComments: (.vendorComments // [])
}
