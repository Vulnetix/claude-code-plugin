# kev.jq: extract Pix-relevant fields from `vulnetix vdb kev list -o /dev/stdout`.
#
# Output-flag quirk: `-o json` writes to file `json`; use `-o /dev/stdout`.
#
# Verified against: `kev list --limit 3` (1 KB raw → ~0.9 KB filtered, modest
# reduction since the response is already lean).
# Top-level keys: count, items, limit, offset, sources, timestamp.
# Each .items[] has: cveId, dateAdded, knownRansomwareCampaignUse, product, source,
# vendorProject, vulnerabilityName.
# Optional fields per source: dueDate, requiredAction, notes. Present in CISA KEV,
# absent in vulncheck-derived entries. Keep the full requiredAction text, because CISA's
# required actions are the authoritative directive and shouldn't be truncated.

{
  count: .count,
  total: ((.items // []) | length),
  limit: .limit,
  offset: .offset,
  sources: .sources,
  hasMore: ((.offset // 0) + ((.items // []) | length) < (.count // 0)),
  items: ([(.items // [])[] | {
    cveId,
    vendor: .vendorProject,
    product,
    name: .vulnerabilityName,
    source,
    dateAdded,
    dueDate: (.dueDate // null),
    knownRansomware: .knownRansomwareCampaignUse,
    requiredAction: (.requiredAction // null),
    notes: (.notes // null)
  }])
}
