# cwe.jq: extract Pix-relevant fields from `vulnetix vdb cwe <id> -V v2 -o json`.
#
# **Verification status: PARTIAL.** Inferred from MITRE-style CWE response.
# Retains all mitigations and consequences (these are the canonical defensive
# guidance) without truncation; caps examples at 10.

{
  cweId: (.cweId // .id),
  name: (.name // null),
  description: (.description // null),
  abstraction: (.abstraction // null),
  status: (.status // null),
  mitigations: ([(.mitigations // [])[] | {
    strategy: (.strategy // null),
    description: (.description // null),
    phase: (.phase // null),
    effectiveness: (.effectiveness // null)
  }]),
  consequences: ([(.consequences // [])[] | {
    scope: (.scope // null),
    impact: (.impact // null),
    note: (.note // null)
  }]),
  detectionMethods: (.detectionMethods // []),
  examples: ([(.examples // [])[0:10][] | {
    cveId: (.cveId // .id),
    description: (.description // null)
  }]),
  relatedAttackPatterns: (.relatedAttackPatterns // [])
}
