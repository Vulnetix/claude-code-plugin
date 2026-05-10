# cwe.jq — extract Pix-relevant fields from `vulnetix vdb cwe <id> -V v2 -o json`.
#
# **Verification status: PARTIAL.** Inferred from MITRE-style CWE response.

{
  cweId: (.cweId // .id),
  name: (.name // null),
  mitigations: ([(.mitigations // [])[0:5][] | {
    strategy: (.strategy // null),
    description: ((.description // "") | if length > 150 then .[:147] + "..." else . end)
  }]),
  consequences: ([(.consequences // [])[] | {scope: (.scope // null), impact: (.impact // null)}]),
  topExamples: ([(.examples // [])[0:3][] | {
    cveId: (.cveId // .id),
    description: ((.description // "") | if length > 100 then .[:97] + "..." else . end)
  }])
}
