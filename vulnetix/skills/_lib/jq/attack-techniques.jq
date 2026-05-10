# attack-techniques.jq — extract Pix-relevant fields from
# `vulnetix vdb attack-techniques get <id> -o /dev/stdout`.
#
# Subcommand: `attack-techniques get <id>` (NOT bare `attack-techniques <id>`).
# Output-flag quirk: `-o json` writes to file `json`; use `-o /dev/stdout`.
#
# Verified against: CVE-2021-44228 (2.6 KB raw → ~0.2 KB filtered).
# Top-level keys: _links, aliases, attackTechniques (often empty for older CVEs),
# count, identifier, state, timestamp, title, total.

{
  id: .identifier,
  total: .total,
  techniques: ([(.attackTechniques // [])[] | {
    id: (.id // .techniqueId),
    name: (.name // null),
    tactic: (.tactic // null),
    inWildCount: (.inWildCount // null)
  }])
}
