# sightings.jq — extract Pix-relevant fields from `vulnetix vdb sightings <id> -o /dev/stdout`.
#
# CLI quirk: `vdb sightings -o json` writes to a file LITERALLY named `json`. Use
# `-o /dev/stdout` to capture to a pipe.
#
# Verified against: CVE-2021-44228 (294 KB raw → ~0.4 KB filtered, 99.9% reduction).
# Top-level keys: _links, aliases, count, daysSinceLastSeen, events (the firehose),
# firstObservation, identifier, lastObservation, state, timestamp, title.

{
  id: .identifier,
  title: (.title // null),
  count: .count,
  firstObservation: .firstObservation,
  lastObservation: .lastObservation,
  daysSinceLastSeen: .daysSinceLastSeen,
  recentEvents: ([(.events // [])[0:5][] | {
    source: (.source // null),
    date: (.date // .observationDate // null),
    summary: ((.summary // .description // "") | if length > 80 then .[:77] + "..." else . end)
  }])
}
