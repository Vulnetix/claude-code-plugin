# fixes.jq — extract Pix-relevant fields from `vulnetix vdb fixes <id> -o json`.
#
# Verified against: CVE-2021-44228 (87 KB raw → ~1.2 KB filtered, ~98.5% reduction).
# Top-level keys: _deprecated, _links, aiAnalysis, cweRemediations, exploitationMaturity,
# fixAvailability, fixes{configurations,distributions,registry,solutions,sourceCode,workarounds},
# identifier, kevRequiredAction, summary{distributionPatches,registryFixes,sourceFixes,
# vendorAdvisories,workarounds}, timeline{datePublished,firstPatchDate,lifecycleStage,timeToPatchDays},
# vendorComments.

{
  id: .identifier,
  fixAvailability: .fixAvailability,
  summary: .summary,
  timeline: .timeline,
  exploitationMaturity: (.exploitationMaturity | if . then {
    level: .level,
    score: .score,
    confidence: .confidence,
    reasoning: .reasoning,
    factors: .factors
  } else null end),
  kevRequiredAction: ((.kevRequiredAction // "") | if length > 200 then .[:197] + "..." else . end),
  fixCounts: {
    registry: ((.fixes.registry // []) | length),
    distributions: ((.fixes.distributions // []) | length),
    sourceCode: ((.fixes.sourceCode // []) | length),
    solutions: ((.fixes.solutions // []) | length),
    workarounds: ((.fixes.workarounds // []) | length),
    configurations: ((.fixes.configurations // []) | length)
  },
  topRegistryFixes: ([(.fixes.registry // [])[0:3][] | {package: (.package // .name), ecosystem, fixedVersion: (.fixedVersion // .fixed_version)}]),
  topSourceFixes: ([(.fixes.sourceCode // [])[0:3][] | {url: (.url // .patchUrl), repo: (.repo // null)}]),
  topDistroPatches: ([(.fixes.distributions // [])[0:3][] | {distro: (.distribution // .distro), package: (.packageName // .package), advisoryId: (.advisoryId // null), patchedVersion: (.patchedVersion // null)}]),
  cweRemediations: ([(.cweRemediations // [])[0:3][] | (if type == "string" then (if length > 150 then .[:147] + "..." else . end) else . end)])
}
