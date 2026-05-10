# ai-list.jq — generic projection for the four AI list endpoints:
#   `vulnetix vdb ai-discoveries`, `ai-in-wild`, `ai-malware`, `ai-assisted-exploits`.
#
# **Verification status: PARTIAL.** Inferred shape `{items[], total, limit, offset,
# hasMore}`. Each item carries CVE id + package/family + a key score + date +
# source + descriptive fields.
#
# Caps at 100 items per page. Keeps full title/summary text since these are
# typically short headline strings.

{
  total: (.total // ((.items // []) | length)),
  hasMore: (.hasMore // false),
  limit: (.limit // null),
  offset: (.offset // null),
  items: ([(.items // [])[0:100][] | {
    cveId: (.cveId // null),
    package: (.packageName // .package // null),
    family: (.family // null),
    severity: (.severity // null),
    score: (.score // .keyScore // null),
    confidence: (.confidence // null),
    date: (.discoveryDate // .observedAt // .date // null),
    source: (.source // null),
    researcher: (.researcher // .author // null),
    title: (.title // null),
    summary: (.summary // .description // null),
    url: (.url // null)
  }])
}
