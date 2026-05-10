# iocs.jq — extract Pix-relevant fields from `vulnetix vdb iocs get <id> -o /dev/stdout`.
#
# Subcommand quirk: bare `vdb iocs <id>` returns help. Must use `iocs get <id>`.
# Output-flag quirk: `-o json` writes to file `json`; use `-o /dev/stdout`.
#
# Verified against: CVE-2021-44228 (70 KB raw → ~1.5 KB filtered, 98% reduction).
# Top-level keys: _links, aliases, count, identifier, shadowserver, sightings, state,
# timestamp, title, total.

{
  id: .identifier,
  total: .total,
  shadowserver: (.shadowserver // null),
  sightingCount: ((.sightings // []) | length),
  topIPs: ([(.sightings // [])[0:10][] | {
    ip: .ip,
    confidence: (.confidence // null),
    reputation: (.reputation // null),
    source: (.source // null),
    firstSeen: (.firstSeen // null),
    lastSeen: (.lastSeen // null)
  }])
}
