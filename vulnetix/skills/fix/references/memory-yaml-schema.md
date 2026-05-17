# Vulnerability Memory File (.vulnetix/memory.yaml)

This skill maintains a `.vulnetix/memory.yaml` file in the repository root that tracks all vulnerability encounters, decisions, and fix outcomes across sessions. **You MUST read this file at the start of every invocation and update it after every action.**

### Schema

```yaml
# .vulnetix/memory.yaml
# Auto-maintained by Vulnetix Claude Code Plugin
# Do not remove — tracks vulnerability decisions, manifest scans, and fix history

schema_version: 1
manifests:                                # Tracked manifest files and SBOM scan history
  package.json:
    path: "package.json"                  # Relative path from repo root
    ecosystem: npm
    last_scanned: "2024-01-15T10:30:00Z"  # ISO 8601 UTC
    sbom_generated: true
    sbom_path: ".vulnetix/scans/package.json.20240115T103000Z.cdx.json"
    vuln_count: 3                         # Vulnerabilities found in last scan
    scan_source: hook                     # hook | fix | exploits | package-search
  services--api--go.mod:
    path: "services/api/go.mod"           # Supports monorepo paths (key uses -- separator)
    ecosystem: go
    last_scanned: "2024-01-15T10:31:00Z"
    sbom_generated: true
    sbom_path: ".vulnetix/scans/services--api--go.mod.20240115T103100Z.cdx.json"
    vuln_count: 0
    scan_source: hook
vulnerabilities:
  CVE-2021-44228:                       # Primary vuln ID (key)
    aliases:                             # Other IDs for the same vuln
      - GHSA-jfh8-c2jp-5v3q
    package: log4j-core
    ecosystem: maven
    discovery:
      date: "2024-01-15T10:30:00Z"      # ISO 8601 UTC
      source: manifest                   # manifest | lockfile | sbom | scan | user | hook
      file: pom.xml                      # The manifest where it was found
      sbom: .vulnetix/scans/pom.xml.cdx.json  # CycloneDX v1.7 SBOM (when produced by scan/hook)
    versions:
      current: "2.14.1"
      current_source: "lockfile: pom.xml"
      fixed_in: "2.17.1"
      fix_source: "registry: Maven Central"
    severity: critical                   # critical | high | medium | low | unknown
    safe_harbour: 0.82                   # 0.00–1.00 confidence score
    status: fixed                        # See VEX Status Mapping below
    justification: null                  # See VEX Justification Mapping below
    action_response: null                # See VEX Action Response Mapping below
    threat_model:                        # Populated by /vulnetix:exploits
      techniques: [T1190, T1059]         # MITRE ATT&CK IDs (internal only)
      tactics:                           # Developer-friendly descriptions (shown to user)
        - "Attackable from the internet"
        - "Can run arbitrary commands"
      attack_vector: network             # network | local | adjacent | physical
      attack_complexity: low             # low | high
      privileges_required: none          # none | low | high
      user_interaction: none             # none | required
      reachability: direct               # direct | transitive | not-found | unknown
                                         # PRIMARY source (deterministic): the CLI's tree-sitter scan.
                                         # `vulnetix vdb vuln <id> --reachability both` already runs by
                                         # default; the shared jq filter exposes the result at
                                         # `.reachability` (queries_run, direct[], transitive[]).
                                         # Map: .direct non-empty → `direct`; .transitive non-empty (and
                                         # .direct empty) → `transitive`; both empty with queries_run>0
                                         # and no skipped_* reason → `not-found`.
                                         # FALLBACK (only when .reachability is null, queries_run==0, or
                                         # a skipped_* reason is present): grep on `affectedRoutines`:
                                         #   vulnetix vdb vuln <id> -o json \
                                         #     | jq -f $CLAUDE_PLUGIN_ROOT/skills/_lib/jq/vuln.jq \
                                         #     | jq -r '.affectedRoutines[] | select(.kind=="function") | .name' \
                                         #     | xargs -I{} git grep -nE '\b{}\b' src/
                                         # routines list empty AND CLI inconclusive → `unknown`.
      exposure: public-facing            # public-facing | internal | local-only | unknown
    cwss:                                # CWSS-derived priority (populated by /vulnetix:exploits)
      score: 87.5                        # 0-100 composite priority score
      priority: P1                       # P1 | P2 | P3 | P4
      factors:
        technical_impact: 100            # 0-100
        exploitability: 95               # 0-100
        exposure: 100                    # 0-100
        complexity: 90                   # 0-100
        repo_relevance: 70               # 0-100
    pocs:                                # PoC sources (from /vulnetix:exploits, never executed)
      - url: "https://exploit-db.com/exploits/12345"
        source: exploitdb
        type: poc
        local_path: ".vulnetix/pocs/CVE-2021-44228/exploit_12345.py"
        fetched_date: "2024-01-15T10:35:00Z"
        verified: true
        analysis: "RCE via JNDI lookup, network vector, no auth"
    dependabot:                          # Populated from GitHub Dependabot via gh CLI
      alert_number: 42                   # Dependabot alert number on this repo
      alert_state: fixed                 # open | dismissed | fixed | auto_dismissed
      alert_url: "https://github.com/owner/repo/security/dependabot/42"
      dismiss_reason: null               # fix_started | inaccurate | no_bandwidth | not_used | tolerable_risk | null
      dismiss_comment: null              # Dismisser's comment, if any
      pr_number: 187                     # Associated Dependabot PR number, or null
      pr_state: merged                   # open | closed | merged | null
      pr_url: "https://github.com/owner/repo/pull/187"
      pr_latest_comment: "LGTM, merging" # Last comment on the PR (for context)
      last_checked: "2024-01-15T10:30:00Z"
    code_scanning:                       # Populated from GitHub CodeQL / code scanning via gh CLI
      alerts:                            # CodeQL alerts correlated to this vuln (matched by CWE)
        - alert_number: 15
          state: dismissed               # open | dismissed | fixed
          rule_id: "java/log4j-injection"
          rule_name: "Log4j injection"
          severity: critical             # critical | high | medium | low | warning | note | error
          dismissed_reason: null         # "false positive" | "won't fix" | "used in tests" | null
          dismissed_comment: null        # Free-text justification (max 280 chars)
          dismissed_by: "octocat"        # GitHub username
          file_path: "src/main/java/App.java"
          start_line: 42
          url: "https://github.com/owner/repo/security/code-scanning/15"
      tool: CodeQL                       # CodeQL | semgrep | etc.
      tool_version: "2.15.0"
      last_checked: "2024-01-15T10:30:00Z"
    secret_scanning:                     # Populated from GitHub secret scanning via gh CLI
      alerts:                            # Secret scanning alerts correlated to this vuln's package/context
        - alert_number: 7
          state: resolved                # open | resolved
          secret_type: "github_personal_access_token"
          secret_type_display: "GitHub Personal Access Token"
          resolution: revoked            # false_positive | wont_fix | revoked | used_in_tests | null
          resolution_comment: "Token rotated and old one revoked"
          resolved_by: "octocat"
          validity: inactive             # active | inactive | unknown
          file_path: "config/settings.py"
          url: "https://github.com/owner/repo/security/secret-scanning/7"
          push_protection_bypassed: false
      last_checked: "2024-01-15T10:30:00Z"
    decision:
      choice: fix-applied                # See User Decision Values below
      reason: "Upgraded to 2.17.1 via version bump"
      date: "2024-01-15T11:00:00Z"
    history:                             # Append-only event log
      - date: "2024-01-15T10:30:00Z"
        event: discovered
        detail: "Found via /vulnetix:fix CVE-2021-44228"
      - date: "2024-01-15T11:00:00Z"
        event: fix-applied
        detail: "Version bumped log4j-core 2.14.1 → 2.17.1 in pom.xml"
```

### VEX Status Mapping (Internal → Developer Language)

Use VEX semantics internally but **always communicate to the user in developer-friendly language**. Never use raw VEX terminology with the user.

| VEX Status | Developer Language | When to use |
|---|---|---|
| `not_affected` | **Not affected** — this vuln doesn't apply to your project | Package not present, code path unreachable, or already mitigated |
| `affected` | **Vulnerable** — your project is exposed, action needed | Package is present at a vulnerable version |
| `fixed` | **Fixed** — a fix has been applied | Version bumped, patch applied, or dependency removed |
| `under_investigation` | **Investigating** — still evaluating the impact | User hasn't decided yet, or analysis is ongoing |

### VEX Justification Mapping (for `not_affected` status)

| VEX Justification | Developer Language | Example |
|---|---|---|
| `component_not_present` | **Package not in this project** | Manifest search found no match |
| `vulnerable_code_not_reachable` | **Vulnerable code path not used** | App imports only safe submodules |
| `vulnerable_code_cannot_be_controlled_by_adversary` | **Not exploitable in this deployment** | Internal-only service, no untrusted input |
| `inline_mitigations_already_exist` | **Already mitigated** | WAF rule, input validation, or config hardening in place |

### VEX Action Response Mapping (for `affected` status)

| VEX Action | Developer Language | When to use |
|---|---|---|
| `will_not_fix` | **Risk accepted** — won't fix, documented reason | User explicitly accepts the risk |
| `will_fix` | **Fix planned** — scheduled for later | User wants to fix but not right now |
| `update` | **Updating** — fix in progress | Actively applying a version bump or patch |

### User Decision Values

These are the `decision.choice` values recorded in the memory file, mapped from user feedback:

| Decision | Maps to VEX | Triggered by user saying |
|---|---|---|
| `fix-applied` | status: `fixed` | "Yes, apply the fix" / fix was successfully applied |
| `risk-accepted` | status: `affected`, action: `will_not_fix` | "We'll accept this risk" / "Won't fix" |
| `not-affected` | status: `not_affected` | "This doesn't affect us" / "Not relevant" |
| `investigating` | status: `under_investigation` | "Let me look into this" / "Need more info" |
| `deferred` | status: `affected`, action: `will_fix` | "We'll fix this later" / "Not now" |
| `mitigated` | status: `not_affected`, justification: `inline_mitigations_already_exist` | "We have a workaround" / "Already handled" |
| `inlined` | status: `fixed` | Dependency was replaced with first-party code |
| `risk-avoided` | status: `not_affected`, justification: `component_not_present` | "We removed the dependency" / "Feature disabled" / "Not deploying this" |
| `risk-transferred` | status: `not_affected`, justification: `vulnerable_code_cannot_be_controlled_by_adversary` | "Our WAF handles it" / "Platform mitigates this" / "Handled by infrastructure" |

### Dependabot Integration

When `gh` CLI is available, check GitHub Dependabot alerts and PRs for additional context. Dependabot state is a **supplementary signal** — it does not override user decisions recorded in the memory file, but it enriches context.

#### Checking gh CLI Availability

```bash
gh auth status 2>/dev/null
```

If this succeeds, the user has `gh` authenticated and you can query Dependabot. If it fails, skip Dependabot checks silently — do not prompt the user to authenticate.

#### Querying Dependabot Alerts

```bash
# Get the repo owner/name from git remote
gh api repos/{owner}/{repo}/dependabot/alerts --jq '[.[] | select(.security_advisory.cve_id == "'"$ARGUMENTS"'" or (.security_advisory.ghsa_id == "'"$ARGUMENTS"'") or (.security_advisory.identifiers[]? | select(.type == "CVE" and .value == "'"$ARGUMENTS"'") ) )] | first'
```

If the vuln ID is a GHSA, also match on `.security_advisory.ghsa_id`. If the vuln ID is a CVE, match on `.security_advisory.cve_id` and the identifiers array.

If no alert matches the exact vuln ID, also try aliases from the memory file entry.

#### Querying Dependabot PRs

```bash
# Find Dependabot PRs referencing this vulnerability or the affected package
gh pr list --author "app/dependabot" --state all --json number,title,state,url,comments --limit 50 | jq '[.[] | select(.title | test("'"$PACKAGE_NAME"'"; "i"))]'
```

For each matching PR, extract:
- PR number, state (open/closed/merged), URL
- The **latest comment** (last item in `.comments[]`): `gh pr view <number> --json comments --jq '.comments[-1].body'`

#### Dependabot Alert State → VEX Mapping

Map Dependabot states to VEX status and user decision values. **Always communicate to the user in developer-friendly language.**

| Dependabot Alert State | Dismiss Reason | VEX Status | Decision Choice | Developer Language |
|---|---|---|---|---|
| `open` | — | `under_investigation` | `investigating` | "Dependabot flagged this — still open, no action taken yet" |
| `dismissed` | `fix_started` | `affected` | `deferred` | "Dependabot dismissed — team started a fix" |
| `dismissed` | `inaccurate` | `not_affected` | `not-affected` | "Dependabot dismissed — team determined this is inaccurate" |
| `dismissed` | `no_bandwidth` | `affected` | `deferred` | "Dependabot dismissed — deferred, no bandwidth" |
| `dismissed` | `not_used` | `not_affected` | `not-affected` | "Dependabot dismissed — vulnerable code not used" |
| `dismissed` | `tolerable_risk` | `affected` | `risk-accepted` | "Dependabot dismissed — risk accepted as tolerable" |
| `fixed` | — | `fixed` | `fix-applied` | "Dependabot reports this as fixed" |
| `auto_dismissed` | — | `not_affected` | `not-affected` | "Dependabot auto-dismissed — no longer applicable" |

**When a Dependabot PR exists:**

| PR State | VEX Interpretation | Developer Language |
|---|---|---|
| `open` | `affected` + `will_fix` | "Dependabot PR #N is open — the team is working on this upgrade" |
| `merged` | `fixed` | "Dependabot PR #N was merged — fix applied via Dependabot" |
| `closed` (not merged) | Check latest PR comment for reason | "Dependabot PR #N was closed without merging — <reason from comments>" |

**For closed (not merged) PRs:** Read the latest comment on the PR to derive the justification. Common patterns:
- "superseded by ..." / "replaced by ..." → decision: `deferred`, reason: paraphrase the comment
- "not needed" / "false positive" → decision: `not-affected`, reason: paraphrase the comment
- "will handle manually" → decision: `deferred`, reason: "Team will handle manually"
- "breaking changes" / "can't upgrade" → decision: `deferred`, reason: paraphrase the comment
- No comments or unclear → decision: `investigating`, reason: "Dependabot PR closed without explanation"

#### When Dependabot and Memory File Disagree

If the memory file has a user decision but Dependabot shows a different state:
- **User decision takes precedence** — it represents a deliberate human choice
- **Flag the discrepancy** to the user: "Note: Dependabot shows this as <state>, but you previously marked it as <decision>. The Dependabot state may be out of sync."
- **Update the `dependabot` section** in the memory file to reflect current Dependabot state regardless — it's a factual record of what GitHub shows

### Code Scanning (CodeQL) Integration

When `gh` CLI is available, query GitHub code scanning alerts for findings that correlate with the current vulnerability. CodeQL alerts are correlated by **CWE match** — if the vulnerability's CWE (from VDB data) matches a CodeQL rule's tags or the rule directly references the vulnerability.

#### Querying Code Scanning Alerts

```bash
# List all open code scanning alerts
gh api repos/{owner}/{repo}/code-scanning/alerts?state=open --jq '[.[] | select(.rule.tags[]? | test("cwe-"; "i"))]'

# Check for alerts matching a specific CWE (extracted from vuln context in Step 2)
gh api repos/{owner}/{repo}/code-scanning/alerts --jq '[.[] | select(.rule.tags[]? | test("CWE-<NUMBER>"; "i"))]'

# Also check dismissed and fixed alerts for prior decisions
gh api repos/{owner}/{repo}/code-scanning/alerts?state=dismissed --jq '[.[] | select(.rule.tags[]? | test("CWE-<NUMBER>"; "i"))]'
gh api repos/{owner}/{repo}/code-scanning/alerts?state=fixed --jq '[.[] | select(.rule.tags[]? | test("CWE-<NUMBER>"; "i"))]'
```

If the repository does not have code scanning enabled, these calls return 403 or 404 — skip silently.

#### Checking Default Setup Status

```bash
gh api repos/{owner}/{repo}/code-scanning/default-setup --jq '{state, languages, query_suite}'
```

If `state` is `not-configured`, note this to the user: "CodeQL is not enabled on this repository. Consider enabling it to catch similar issues in code."

#### Code Scanning Alert State → VEX Mapping

| Code Scanning State | Dismissed Reason | VEX Status | Decision Choice | Developer Language |
|---|---|---|---|---|
| `open` | — | `under_investigation` | `investigating` | "CodeQL flagged this pattern — still open" |
| `dismissed` | `false positive` | `not_affected` | `not-affected` | "CodeQL alert dismissed — false positive" |
| `dismissed` | `won't fix` | `affected` | `risk-accepted` | "CodeQL alert dismissed — risk accepted" |
| `dismissed` | `used in tests` | `not_affected` | `not-affected` | "CodeQL alert dismissed — only in test code" |
| `fixed` | — | `fixed` | `fix-applied` | "CodeQL reports the code pattern is fixed" |

**Enriching vulnerability context with CodeQL findings:**

When a CodeQL alert matches the vulnerability's CWE:
- The `most_recent_instance.location` tells you **exactly which file and line** the vulnerable pattern appears — include this in the fix report
- The `rule.full_description` provides CodeQL's analysis of the weakness — quote relevant parts
- If multiple instances exist, list the affected files so the user knows everywhere the pattern occurs
- If the alert is `fixed`, this is strong evidence the code-level vulnerability has been addressed (complements a dependency version bump)
- Use `dismissed_comment` as the justification text when surfacing prior decisions

#### Autofix Integration (CodeQL AI Suggestions)

If a CodeQL alert has an autofix available, check its status:

```bash
gh api repos/{owner}/{repo}/code-scanning/alerts/{alert_number}/autofix --jq '{status}'
```

| Autofix Status | What to tell the user |
|---|---|
| `success` | "CodeQL has an AI-suggested fix for this code pattern — review it on GitHub" |
| `pending` | "CodeQL is generating an AI fix suggestion — check back later" |
| `error` | "CodeQL autofix failed for this alert" |
| `outdated` | "CodeQL's autofix is outdated — the code has changed since it was generated" |

If autofix status is `success`, suggest the user review it alongside any dependency fix — code-level fixes and dependency upgrades are complementary.

### Secret Scanning Integration

When `gh` CLI is available, query GitHub secret scanning alerts. Secret scanning findings relate to vulnerability management when:
- A leaked secret could be used to exploit the vulnerability (e.g., leaked API key + RCE = worse impact)
- The vulnerability is in credential handling code (CWE-798, CWE-321, CWE-259)
- The fix involves rotating secrets that may have been exposed

#### Querying Secret Scanning Alerts

```bash
# List all open secret scanning alerts
gh api repos/{owner}/{repo}/secret-scanning/alerts?state=open

# List resolved alerts (to check for prior decisions)
gh api repos/{owner}/{repo}/secret-scanning/alerts?state=resolved
```

If the repository does not have secret scanning enabled, these calls return 403 or 404 — skip silently.

**Correlation with vulnerability context:**
- If the vulnerability's CWE relates to credential handling (CWE-798 hard-coded credentials, CWE-321 hard-coded cryptographic key, CWE-259 hard-coded password, CWE-200 information exposure), check for secret scanning alerts in the same files
- If the vulnerable package handles authentication/secrets (e.g., `jsonwebtoken`, `bcrypt`, `passport`, `oauth2`), check for leaked secrets that might need rotation after fixing

#### Secret Scanning Alert State → VEX Mapping

| Secret Scanning State | Resolution | VEX Status | Decision Choice | Developer Language |
|---|---|---|---|---|
| `open` | — | `under_investigation` | `investigating` | "Exposed secret detected — still open, needs rotation" |
| `resolved` | `revoked` | `fixed` | `fix-applied` | "Secret was rotated and old one revoked" |
| `resolved` | `false_positive` | `not_affected` | `not-affected` | "Secret alert dismissed — false positive" |
| `resolved` | `wont_fix` | `affected` | `risk-accepted` | "Secret alert dismissed — risk accepted" |
| `resolved` | `used_in_tests` | `not_affected` | `not-affected` | "Secret alert dismissed — only used in test fixtures" |
| `resolved` | `pattern_edited` | `not_affected` | `not-affected` | "Secret scanning pattern was updated — no longer matches" |
| `resolved` | `pattern_deleted` | `not_affected` | `not-affected` | "Secret scanning pattern was removed" |

**Push protection context:**
If `push_protection_bypassed` is `true`, note this to the user — it means someone deliberately pushed a secret past GitHub's push protection. Include the bypasser's username and their comment (if any) for audit trail:
```
Secret push protection was bypassed by <user>: "<comment>"
```

**Secret validity:**
If `validity` is `active`, flag urgently: "This secret is still active — rotate it immediately." If `inactive`, note: "Secret has been deactivated." If `unknown`, note: "Secret validity could not be verified — recommend rotating as a precaution."

#### When GHAS and Memory File Disagree

Same principle as Dependabot:
- **User decision takes precedence** over GitHub alert state
- **Flag discrepancies** to the user
- **Always update** the `code_scanning` and `secret_scanning` sections to reflect current GitHub state — they are factual records

### Reading and Interpreting Prior State

When the memory file contains an entry for the current vuln ID (or any of its aliases):

1. **Show the user what's known** — previous status, decision, and when it was last updated
2. **Show GitHub security context** — surface all available GHAS data:
   - Dependabot: "Dependabot alert #N: <state>. PR #N: <state>."
   - CodeQL: "CodeQL alert #N (<rule_id>): <state> in <file>:<line>"
   - Secret scanning: "Secret scanning alert #N (<secret_type>): <state>, validity: <active|inactive|unknown>"
3. **Highlight changes** — if the vulnerability context has changed (new severity, new fix available, CISA KEV listing added, any GHAS alert state changed), flag this to the user
4. **Respect prior decisions** — if the user previously marked a vuln as "Risk accepted" or "Not affected", remind them of that decision and ask if they want to reassess rather than re-proposing the same fix
5. **Update, don't duplicate** — update the existing entry rather than creating a new one

