# remediation.jq: extract Pix-relevant fields from
# `vulnetix vdb remediation plan <id> -V v2 -o json`.
#
# Verified against: CVE-2021-44228 (467 KB raw → ~28 KB filtered, ~94%).
#
# CORRECTED 2026-08-10. The previous version carried a "Verification status:
# PARTIAL" banner and inferred its field paths. Checked against a live response,
# most of them were wrong:
#
#   - `.status`, `.confidence`, `.cweGuidance`, `.threatIntel` do not exist, so
#     the filter emitted four nulls.
#   - `.workarounds[]` was read for {description, effectiveness, sideEffects};
#     the real field is a plain array, empty for this advisory.
#   - `.timeline`, `.ssvc`, `.severity`, `.kevEntries`, `.distributionPatches`,
#     `.registryFixes` and `.sourceFixes` all exist, all drive the decision, and
#     every one of them was dropped.
#   - each action is {title, description, type, priority, effort, impact,
#     buildFromSourceRequired, steps[]}, not {action, packages, verifyCommand,
#     verificationSteps, rollback, notes}.
#
# Where the 467 KB goes:
#   descriptions  159 KB   per-source prose, near-duplicate
#   sourceFixes   146 KB   800 commit/diff URLs
#   cwes           68 KB   36 entries, each with long-form guidance
#   snortRules     63 KB   detection content, better fetched deliberately
#   actions        12 KB   37 ranked, actionable steps  ← the answer
#
# So: keep the ranked actions in full field detail, keep every decision scalar,
# and reduce the four bulk arrays to counts plus a bounded sample.

{
  id: .identifier,
  state: (.state // null),
  title: (.title // null),
  description: ((.description // "") | if length > 600 then .[:597] + "..." else . end),

  # Decision scalars. All small, all kept whole.
  fixAvailability: (.fixAvailability // null),
  severity: (.severity // null),
  ssvc: (.ssvc // null),
  timeline: (.timeline // null),
  exploitationSignals: (.exploitationSignals // null),
  kevEntries: (.kevEntries // []),

  # The ranked plan, the answer to "how do I fix it".
  actionCount: ((.actions // []) | length),
  actions: ([(.actions // [])[0:25][] | {
    title: (.title // null),
    description: (.description // null),
    type: (.type // null),
    priority: (.priority // null),
    effort: (.effort // null),
    impact: (.impact // null),
    buildFromSourceRequired: (.buildFromSourceRequired // null),
    steps: (.steps // [])
  }]),

  distributionPatchCount: ((.distributionPatches // []) | length),
  distributionPatches: ((.distributionPatches // [])[0:20]),
  registryFixes: (.registryFixes // null),

  # 800 commit URLs is not a decision input; a count plus a handful is.
  sourceFixes: {
    count: ((.sourceFixes // []) | length),
    sample: ((.sourceFixes // [])[0:10])
  },

  # Long-form guidance dropped; ids and technique mappings are the pivot.
  # Fetch `vdb cwe guidance <id>` deliberately when you need the prose.
  cwes: ([(.cwes // [])[] | {
    cweId: (.cweId // null),
    name: (.name // null),
    attackTechniques: (.attackTechniques // null)
  }]),

  workarounds: (.workarounds // []),
  solutions: (.solutions // []),
  configurations: (.configurations // []),
  snortRuleCount: (.snortRuleCount // null),
  references: ((.references // [])[0:15])
}
