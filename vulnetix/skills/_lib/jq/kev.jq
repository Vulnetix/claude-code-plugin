# kev.jq — extract Pix-relevant fields from `vulnetix vdb kev list -o /dev/stdout`.
#
# Output-flag quirk: `-o json` writes to file `json`; use `-o /dev/stdout`.
#
# Verified against: `kev list --limit 3` (1 KB raw → ~0.5 KB filtered).
# Top-level keys: count, items, limit, offset, sources, timestamp.
# Each .items[] has: cveId, dateAdded, knownRansomwareCampaignUse, product, source,
# vendorProject, vulnerabilityName.
# (Optional fields per source: dueDate, requiredAction, notes — present in CISA KEV,
# absent in vulncheck-derived entries.)

{
  count: .count,
  total: ((.items // []) | length),
  hasMore: (.offset + (.items // [] | length) < .count),
  items: ([(.items // [])[] | {
    cveId,
    vendor: .vendorProject,
    product,
    name: .vulnerabilityName,
    source,
    dateAdded,
    dueDate: (.dueDate // null),
    knownRansomware: .knownRansomwareCampaignUse,
    requiredAction: ((.requiredAction // "") | if length > 200 then .[:197] + "..." else . end)
  }])
}
