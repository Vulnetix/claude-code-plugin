# packages.jq — extract Pix-relevant fields from `vulnetix vdb packages search <name> -o json`.
#
# Verified against: `packages search express` (7 KB raw → ~1.5 KB filtered, ~78% reduction).
# Top-level keys: capped, ecosystem, hasMore, limit, offset, packages, query, timestamp, total,
# upstreamSync.
# Each .packages[] item: _links, cloudLocators, ecosystems, eolStatus, exploitationSignals
# {crowdSecSightings, exploitCount, inCisaKev, inVulnCheckKev}, name, latestVersion, ...

{
  query: .query,
  total: .total,
  hasMore: .hasMore,
  packages: ([(.packages // [])[] | {
    name: .name,
    ecosystems: (.ecosystems // []),
    latestVersion: (.latestVersion // null),
    vulnerabilityCount: (.vulnerabilityCount // 0),
    maxSeverity: (.maxSeverity // null),
    eolStatus: (.eolStatus // null),
    exploitationSignals: (.exploitationSignals // null)
  }])
}
