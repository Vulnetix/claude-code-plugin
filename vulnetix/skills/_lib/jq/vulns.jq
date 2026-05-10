# vulns.jq — extract Pix-relevant fields from `vulnetix vdb vulns <package> -o json`.
#
# **Verification status: PARTIAL.** Live capture against `vulns express` repeatedly
# rate-limited during planning. Field paths inferred from
# /home/chris/GitHub/Vulnetix/cli/pkg/vdb/api.go::VulnerabilitiesResponse. Re-verify on
# first use; if shape differs, update this filter.
#
# Inferred top-level: {packageName, total, vulnerabilities[], limit, offset, hasMore}.
# Inferred per-vuln: {cveId or version, severity, cvss, epss, fixedVersion, affectedRange, summary}.

{
  package: (.packageName // .name),
  total: (.total // ((.vulnerabilities // []) | length)),
  hasMore: (.hasMore // false),
  vulns: ([(.vulnerabilities // [])[] | {
    id: (.cveId // .id // .version),
    severity: (.severity // null),
    cvss: (.cvss // .cvssScore // null),
    epss: (.epss // null),
    affectedRange: (.affectedRange // .versions // null),
    fixedVersion: (.fixedVersion // .fixed_version // null),
    summary: ((.summary // .description // "") | if length > 120 then .[:117] + "..." else . end)
  }])
}
