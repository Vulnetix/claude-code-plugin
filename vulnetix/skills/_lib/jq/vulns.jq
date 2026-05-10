# vulns.jq — extract Pix-relevant fields from `vulnetix vdb vulns <package> -o json`.
#
# **Verification status: PARTIAL.** Live capture against `vulns express` repeatedly
# rate-limited during planning. Field paths inferred from
# /home/chris/GitHub/Vulnetix/cli/pkg/vdb/api.go::VulnerabilitiesResponse. Re-verify
# on first use; if shape differs, update this filter.
#
# Inferred top-level: {packageName, total, vulnerabilities[], limit, offset, hasMore}.
# Inferred per-vuln: cveId/id, severity, cvss, epss, fixedVersion, affectedRange,
# summary, references, datePublished, dateUpdated, kev, exploitationMaturity.
#
# Retains all per-vuln fields rather than truncating. Caps the list at 100
# entries to bound output for packages with hundreds of CVEs (caller can
# paginate via --limit/--offset).

{
  package: (.packageName // .name),
  total: (.total // ((.vulnerabilities // []) | length)),
  hasMore: (.hasMore // false),
  limit: (.limit // null),
  offset: (.offset // null),
  vulns: ([(.vulnerabilities // [])[0:100][] | {
    id: (.cveId // .id // .version),
    aliases: (.aliases // []),
    severity: (.severity // null),
    cvss: (.cvss // .cvssScore // null),
    epss: (.epss // null),
    kev: (.kev // .inKev // null),
    exploitationMaturity: (.exploitationMaturity // null),
    affectedRange: (.affectedRange // .versions // null),
    fixedVersion: (.fixedVersion // .fixed_version // null),
    datePublished: (.datePublished // null),
    dateUpdated: (.dateUpdated // null),
    summary: (.summary // .description // null),
    references: ((.references // [])[0:5])
  }])
}
