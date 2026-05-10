# purl.jq — extract Pix-relevant fields from `vulnetix vdb purl <purl> -o /dev/stdout`.
#
# **Verification status: PARTIAL.** Live capture against `pkg:npm/lodash@4.17.21`
# returned 0 bytes within rate-limit budget during planning. Field paths inferred
# from cli/cmd/vdb_purl_test.go. Re-verify on first use.
#
# Inferred top-level: combines package metadata + vulnerability list — likely
# {purl, packageName, ecosystem, version, vulnerabilities[], maxSeverity}.

{
  purl: (.purl // null),
  package: {
    name: (.packageName // .name // null),
    ecosystem: (.ecosystem // null),
    version: (.version // null)
  },
  vulnCount: ((.vulnerabilities // []) | length),
  maxSeverity: (.maxSeverity // null),
  vulns: ([(.vulnerabilities // [])[0:10][] | {
    id: (.cveId // .id),
    severity: (.severity // null),
    epss: (.epss // null),
    fixedVersion: (.fixedVersion // null)
  }])
}
