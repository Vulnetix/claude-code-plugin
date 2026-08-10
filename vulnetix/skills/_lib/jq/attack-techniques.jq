# attack-techniques.jq: extract Pix-relevant fields from
# `vulnetix vdb attack-techniques get <id> -o /dev/stdout`.
#
# Subcommand: `attack-techniques get <id>` (NOT bare `attack-techniques <id>`).
# Output-flag quirk: `-o json` writes to file `json`; use `-o /dev/stdout`.
#
# Verified against: CVE-2021-44228. Note `attackTechniques: []` was empty for
# this fixture, but the filter is shaped for the populated case as well. Top-level
# keys: _links, aliases, attackTechniques, count, identifier, state, timestamp,
# title, total.
#
# Per-technique fields (when populated): id, name, tactic, subtechniques,
# inWildCount, mitigations, detections, references. Keep all of them; ATT&CK
# data is the canonical defensive guidance.

{
  id: .identifier,
  title: (.title // null),
  total: .total,
  count: .count,
  techniques: ([(.attackTechniques // [])[] | {
    id: (.id // .techniqueId),
    name: (.name // null),
    tactic: (.tactic // null),
    subtechniques: (.subtechniques // []),
    inWildCount: (.inWildCount // null),
    mitigations: (.mitigations // []),
    detections: (.detections // []),
    description: (.description // null),
    references: (.references // [])
  }])
}
