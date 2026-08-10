# triage.jq: extract Pix-relevant fields from `vulnetix vdb triage [flags] -o json`.
#
# **Verification status: PARTIAL.** The `triage` endpoint shape is implementation-
# dependent (community vs. authenticated). Inferred from cli/cmd/vdb_triage.go and
# the v1.3 SOC-triage skill. Re-verify on first use.
#
# Caps at 200 items (caller paginates with --limit/--offset). Per-item retains
# all triage signals so the LLM can compute its own ordering if desired.

{
  total: (.total // ((.items // []) | length)),
  hasMore: (.hasMore // false),
  limit: (.limit // null),
  offset: (.offset // null),
  triage: ([(.items // [])[0:200][] | {
    cveId: (.cveId // .id),
    package: (.packageName // .package // null),
    ecosystem: (.ecosystem // null),
    severity: (.severity // null),
    cvss: (.cvss // null),
    epss: (.epss // null),
    inKev: (.inKev // .kev // false),
    inVulnCheckKev: (.inVulnCheckKev // false),
    exploitationMaturity: (.exploitationMaturity // null),
    exploitSignalCount: ((.exploitSignals // .exploits // []) | length),
    priority: (.priority // null),
    action: (.action // null),
    affectedVersion: (.affectedVersion // null),
    fixedVersion: (.fixedVersion // null)
  }])
}
