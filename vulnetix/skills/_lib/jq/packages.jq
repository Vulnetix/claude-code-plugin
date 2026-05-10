# packages.jq — extract Pix-relevant fields from `vulnetix vdb packages search <name> -o json`.
#
# Verified against: `packages search express` (7 KB raw → ~5 KB filtered, ~28% reduction).
# Top-level keys: capped, ecosystem, hasMore, limit, offset, packages, query,
# timestamp, total, upstreamSync.
#
# Each `.packages[]` carries:
#   - identity: packageName, product, vendor, ecosystems, generatedCpe, repositoryUrl
#   - risk:     vulnerabilityCount, maxSeverity, eolStatus, scorecardScore
#   - exploit:  exploitationSignals{crowdSecSightings, exploitCount, inCisaKev,
#                                    inVulnCheckKev, xdbCount}
#   - safeHarbour: {highestScore, recommendedVersions} ← THE recommendation
#   - versionCount, versions[] (each has its own safeHarbour score per version)
#   - hasProvenance, matchSources, cloudLocators
#
# Retains everything except _links (navigation) and oversized version lists
# (cap at 10 versions per package — caller can `vdb versions` for full list).

{
  query: .query,
  total: .total,
  hasMore: .hasMore,
  ecosystem: .ecosystem,
  packages: ([(.packages // [])[] | {
    packageName: .packageName,
    product: (.product // null),
    vendor: (.vendor // null),
    ecosystems: (.ecosystems // []),
    repositoryUrl: (.repositoryUrl // null),
    generatedCpe: (.generatedCpe // null),
    matchSources: (.matchSources // []),
    hasProvenance: (.hasProvenance // false),
    eolStatus: (.eolStatus // null),
    scorecardScore: (.scorecardScore // null),
    vulnerabilityCount: (.vulnerabilityCount // 0),
    maxSeverity: (.maxSeverity // null),
    exploitationSignals: (.exploitationSignals // null),
    safeHarbour: (.safeHarbour // null),
    cloudLocators: (.cloudLocators // null),
    versionCount: (.versionCount // 0),
    versions: ([(.versions // [])[0:10][] | {
      version: .version,
      ecosystem: .ecosystem,
      publishedAt: .publishedAt,
      daysSinceRelease: .daysSinceRelease,
      cveIds: (.cveIds // []),
      sources: (.sources // []),
      safeHarbour: (.safeHarbour // null)
    }])
  }])
}
