# sightings.jq: extract Pix-relevant fields from
# `vulnetix vdb sightings <id> -o /dev/stdout`.
#
# CLI quirk: `vdb sightings -o json` writes to a file LITERALLY named `json`. Use
# `-o /dev/stdout` to capture to a pipe.
#
# Verified against: CVE-2021-44228 (294 KB raw → ~5 KB filtered, ~98% reduction).
# Top-level keys: _links, aliases, count, daysSinceLastSeen, events (firehose of
# daily count rows), firstObservation, identifier, lastObservation, state,
# timestamp, title.
#
# Each event: {at, count, lane, source}, a daily Shadowserver-style aggregation.
# Pix needs the timeline summary, NOT every daily row. Aggregates events by
# source+lane and surfaces per-source first-seen / last-seen / total-count /
# peak-day so the LLM gets a chronological story instead of 2K rows.

{
  id: .identifier,
  title: (.title // null),
  count: .count,
  firstObservation: .firstObservation,
  lastObservation: .lastObservation,
  daysSinceLastSeen: .daysSinceLastSeen,
  totalEvents: ((.events // []) | length),

  # Per-source aggregation: pivot 2K events to ~5 rows.
  bySource: (
    [(.events // []) | group_by(.source + "|" + (.lane // ""))[] | {
      source: .[0].source,
      lane: .[0].lane,
      eventCount: length,
      total: ([.[] | .count // 0] | add),
      firstSeen: ([.[] | .at // ""] | min),
      lastSeen: ([.[] | .at // ""] | max),
      peak: (max_by(.count // 0) | {date: .at, count: .count})
    }] | sort_by(-.total)
  ),

  # Recent events (top 20 by date), raw data points for charts.
  recentEvents: ([.events // [] | sort_by(.at) | reverse | .[0:20][] | {
    at: .at,
    source: .source,
    lane: .lane,
    count: .count
  }])
}
