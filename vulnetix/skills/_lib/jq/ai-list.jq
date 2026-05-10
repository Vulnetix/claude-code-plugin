# ai-list.jq — generic projection for the four AI list endpoints:
#   `vulnetix vdb ai-discoveries`, `ai-in-wild`, `ai-malware`, `ai-assisted-exploits`.
#
# **Verification status: PARTIAL.** Inferred shape `{items[], total, limit, offset, hasMore}`.
# Each item carries CVE id + package/family + a key score + date + source.

{
  total: (.total // ((.items // []) | length)),
  hasMore: (.hasMore // false),
  items: ([(.items // [])[] | {
    cveId: (.cveId // null),
    package: (.packageName // .family // null),
    score: (.score // .keyScore // null),
    date: (.discoveryDate // .observedAt // .date // null),
    source: (.source // null),
    summary: ((.summary // .title // "") | if length > 120 then .[:117] + "..." else . end)
  }])
}
