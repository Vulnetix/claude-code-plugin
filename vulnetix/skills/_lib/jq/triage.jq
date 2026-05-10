# triage.jq — extract Pix-relevant fields from `vulnetix vdb triage [flags] -o json`.
#
# **Verification status: PARTIAL.** The `triage` endpoint shape is implementation-
# dependent (community vs. authenticated). Inferred from cli/cmd/vdb_triage.go and
# the v1.3 SOC-triage skill. Re-verify on first use.

{
  total: (.total // ((.items // []) | length)),
  hasMore: (.hasMore // false),
  triage: ([(.items // [])[] | {
    cveId: (.cveId // .id),
    package: (.packageName // .package // null),
    severity: (.severity // null),
    epss: (.epss // null),
    inKev: (.inKev // .kev // false),
    exploitSignals: ((.exploitSignals // .exploits // []) | length),
    priority: (.priority // null),
    action: (.action // null)
  }])
}
