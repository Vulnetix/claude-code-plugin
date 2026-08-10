# vulns.jq — extract Pix-relevant fields from `vulnetix vdb vulns <package> -o json`.
#
# Verified against: `GET /v2/express/vulns` (84 KB raw → ~12 KB filtered, ~86%).
#
# CORRECTED 2026-08-10. The previous version carried a "Verification status:
# PARTIAL" banner and read `.vulnerabilities[]` as an array of per-CVE objects
# with severity/cvss/epss/fixedVersion fields. That shape does not exist. Run
# against live data the old filter collapsed an 84 KB response to 83 bytes of
# nulls — every field it named was absent.
#
# What the endpoint actually returns:
#   {packageName, resolvedMode, resolvedNames[], total, totalCVEs,
#    limit, offset, hasMore, versions: [{version, ecosystem, sources[], cveIds[]}]}
#
# So this is a version→advisory map, not a vulnerability list. `total` counts
# VERSIONS (305 for express) while `totalCVEs` counts distinct advisories (40).
#
# The same advisory ids repeat across nearly every version, so emitting the full
# cross product is almost entirely duplication. The distinct id set answers "what
# affects this package"; the per-version breakdown is capped at a sample. Follow
# up with `vdb vuln <id>` for severity, KEV status and remediation — none of
# which this endpoint carries.

{
  package: .packageName,
  resolvedMode: (.resolvedMode // null),
  resolvedNames: (.resolvedNames // []),
  totalCVEs: (.totalCVEs // null),
  totalVersions: (.total // ((.versions // []) | length)),
  hasMore: (.hasMore // false),
  limit: (.limit // null),
  offset: (.offset // null),

  # Distinct advisory ids across the whole page — the authoritative answer.
  cveIds: ([(.versions // [])[].cveIds // []] | flatten | unique | .[0:300]),

  # Representative sample; the ids repeat across versions.
  versions: ([(.versions // [])[0:20][] | {
    version: (.version // null),
    ecosystem: (.ecosystem // ""),
    sources: (.sources // []),
    cveIds: ((.cveIds // [])[0:25])
  }])
}
