# iocs.jq — extract Pix-relevant fields from `vulnetix vdb iocs get <id> -o /dev/stdout`.
#
# Subcommand quirk: bare `vdb iocs <id>` returns help. Must use `iocs get <id>`.
# Output-flag quirk: `-o json` writes to file `json`; use `-o /dev/stdout`.
#
# Verified against: CVE-2021-44228 (70 KB raw → ~22 KB filtered, ~69% reduction).
# Top-level keys: _links, aliases, count, identifier, shadowserver, sightings,
# state, timestamp, title, total.
#
# Retains: full shadowserver block (count1d/7d/30d/90dAvg + lastObservationDate +
# topCountries — all metric data), aliases, all sightings (typically capped at
# ~200 by the API; each has confidence/firstSeen/ip/lastSeen/reputation/source/
# falsePositivesCount/uuid). For very large sighting lists, the LLM can re-call
# with --limit and country/asn filters via `vulnetix vdb iocs list`.

{
  id: .identifier,
  title: .title,
  total: .total,
  shadowserver: (.shadowserver // null),
  sightingCount: ((.sightings // []) | length),

  # Per-source aggregation: confidence + reputation + counts.
  bySource: (
    [(.sightings // []) | group_by(.source)[] | {
      source: .[0].source,
      count: length,
      reputations: ([.[] | .reputation] | unique),
      confidences: ([.[] | .confidence] | unique),
      firstSeen: ([.[] | .firstSeen // ""] | min),
      lastSeen: ([.[] | .lastSeen // ""] | max)
    }] | sort_by(-.count)
  ),

  # Sample 50 sightings (full set typically 200 capped server-side).
  sightings: ([(.sightings // [])[0:50][] | {
    ip: .ip,
    confidence: .confidence,
    reputation: .reputation,
    source: .source,
    firstSeen: .firstSeen,
    lastSeen: .lastSeen,
    falsePositivesCount: (.falsePositivesCount // 0)
  }])
}
