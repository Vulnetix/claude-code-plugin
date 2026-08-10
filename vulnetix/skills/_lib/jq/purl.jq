# purl.jq: extract Pix-relevant fields from `vulnetix vdb purl <purl> -o /dev/stdout`.
#
# **Verification status: PARTIAL.** Live capture against `pkg:npm/lodash@4.17.21`
# returned 0 bytes within rate-limit budget during planning. Field paths inferred
# from cli/cmd/vdb_purl_test.go. Re-verify on first use.
#
# Likely shape: package metadata + vulnerabilities, a hybrid of the
# `packages search` and `vulns` responses.

{
  purl: (.purl // null),
  package: {
    name: (.packageName // .name // null),
    ecosystem: (.ecosystem // null),
    version: (.version // null),
    vendor: (.vendor // null),
    repositoryUrl: (.repositoryUrl // null)
  },
  exploitationSignals: (.exploitationSignals // null),
  safeHarbour: (.safeHarbour // null),
  scorecardScore: (.scorecardScore // null),
  eolStatus: (.eolStatus // null),
  vulnerabilityCount: (.vulnerabilityCount // ((.vulnerabilities // []) | length)),
  maxSeverity: (.maxSeverity // null),
  vulns: ([(.vulnerabilities // [])[0:50][] | {
    id: (.cveId // .id),
    severity: (.severity // null),
    epss: (.epss // null),
    kev: (.kev // .inKev // null),
    fixedVersion: (.fixedVersion // null),
    affectedRange: (.affectedRange // .versions // null),
    summary: (.summary // .description // null)
  }])
}
