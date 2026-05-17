# Workflow

### Step 0: Load Vulnerability Memory and Prior SBOMs

Before anything else:

**0a. Load memory file:**
1. Use **Glob** to search for `.vulnetix/memory.yaml` in the repo root
2. If it exists, use **Read** to load it
3. Check if the current vuln ID (from `$ARGUMENTS`) or any known aliases appear in the file
4. If a prior entry exists:
   - Display to the user: `Previously seen: <vulnId> — Status: <developer-friendly status> (as of <date>). Reason: <decision reason>`
   - If `cwss` data exists from a prior `/vulnetix:exploits` analysis, display: `Priority: <P1/P2/P3/P4> (<score>) — "<priority description>"` and use the threat model context to inform fix urgency.
   - If status is `fixed` and no new information contradicts it, confirm the fix is still in place by checking the current installed version. If the version has regressed, update the status to `affected` and proceed with the fix workflow.
   - If status is `risk-accepted` or `not-affected`, ask: "You previously marked this as <status>. Has anything changed, or would you like to reassess?"
   - If status is `investigating` or `deferred`, proceed with the fix workflow and note this is a follow-up.
   - If the entry has a `discovery.sbom` path, read that CycloneDX file for additional context (affected components, version ranges, severity ratings from the original scan).
5. If no prior entry exists, proceed normally — a new entry will be created in Step 8.

**0b. Check for existing CycloneDX SBOMs:**
1. Use **Glob** for `.vulnetix/scans/*.cdx.json`
2. If SBOMs exist, scan them for the current vuln ID — this provides pre-existing context about which manifests surfaced this vulnerability and what component versions were scanned
3. Reference the SBOM path in the memory entry's `discovery.sbom` field when creating or updating entries

**0c. Check Dependabot via gh CLI:**
1. Run `gh auth status 2>/dev/null` — if it fails, skip this step silently
2. If `gh` is available, query Dependabot alerts for this vuln ID (see "Querying Dependabot Alerts" above)
3. If a matching alert is found:
   - Display to the user: `Dependabot alert #<N>: <developer-friendly state>` (using the mapping table)
   - If a Dependabot PR exists, display: `Dependabot PR #<N>: <state>` with the latest comment summary
   - If the alert is `dismissed` or `fixed`, show the reason
4. If the memory file already has a `dependabot` section for this vuln, compare with current GitHub state and flag any changes: `"Dependabot state changed: <old> → <new>"`
5. Update the `dependabot` section in the memory entry with current state (will be persisted in Step 8)
6. Use Dependabot context to inform fix urgency:
   - Open alert + open PR → "A Dependabot upgrade PR already exists — consider reviewing and merging PR #N instead of manual fix"
   - Open alert + no PR → proceed with normal fix workflow
   - Open alert + closed PR → check PR comments for context on why it was closed — inform fix approach accordingly

**0d. Check Code Scanning (CodeQL) via gh CLI:**
1. Skip if `gh` auth failed in 0c
2. Extract the CWE ID from the vulnerability context (fetched in Step 2, but pre-check here if the memory file already has `threat_model` data or known CWE from prior analysis)
3. Query code scanning alerts matching the CWE:
   ```bash
   gh api repos/{owner}/{repo}/code-scanning/alerts --jq '[.[] | select(.rule.tags[]? | test("CWE-<NUMBER>"; "i"))]'
   ```
4. If CodeQL alerts are found:
   - Display: `CodeQL alert #<N> (<rule_id>): <state> in <file>:<line>` for each
   - If any alert is `dismissed`, show the reason and comment
   - If any alert has autofix status `success`, note: "CodeQL has an AI-suggested fix available"
5. Check default setup status to inform the user if CodeQL is not enabled:
   ```bash
   gh api repos/{owner}/{repo}/code-scanning/default-setup --jq '.state'
   ```
   If `not-configured`, note: "CodeQL is not enabled on this repo — consider enabling it for ongoing code-level detection of this weakness class"
6. If the memory file has a prior `code_scanning` section, compare alert states and flag changes
7. Store CodeQL findings for persistence in Step 8

**0e. Check Secret Scanning via gh CLI:**
1. Skip if `gh` auth failed in 0c
2. Determine if secret scanning is relevant to this vulnerability:
   - Check if the CWE relates to credential handling (CWE-798, CWE-321, CWE-259, CWE-200, CWE-522, CWE-256)
   - Check if the affected package handles authentication/secrets
3. If relevant, query secret scanning alerts:
   ```bash
   gh api repos/{owner}/{repo}/secret-scanning/alerts?state=open
   ```
4. If alerts are found in files that overlap with the vulnerability's affected code:
   - Display: `Secret scanning alert #<N> (<secret_type>): <state>, validity: <validity>`
   - If `validity` is `active`, flag urgently: "Active secret detected — rotate immediately, especially given this vulnerability"
   - If `push_protection_bypassed`, note the bypass for audit context
5. Also check resolved alerts for prior decisions:
   ```bash
   gh api repos/{owner}/{repo}/secret-scanning/alerts?state=resolved --jq '[.[] | select(.resolution != null)]'
   ```
6. If the memory file has a prior `secret_scanning` section, compare and flag state changes
7. Store secret scanning findings for persistence in Step 8

### Step 0f: Ensure Vulnetix CLI is Available

Before running any `vulnetix` command, verify the CLI is callable:

```bash
command -v vulnetix &>/dev/null && vulnetix --version
```

If `vulnetix` is not found, install it automatically using this priority:

1. **Homebrew** (if `brew` exists): `brew install vulnetix/tap/vulnetix`
2. **Scoop** (Windows, if `scoop` exists): `scoop bucket add vulnetix https://github.com/Vulnetix/scoop-bucket && scoop install vulnetix`
3. **Nix** (if NixOS or `nix` exists): `nix profile install github:Vulnetix/cli`
4. **GitHub releases** (if `curl`/`wget` exist): Download the correct binary for the OS/arch from `https://github.com/Vulnetix/cli/releases/latest`, extract to `~/.local/bin/`, and `chmod +x`
5. **Go install** (if `go` exists): `go install github.com/Vulnetix/cli/cmd/vulnetix@latest`

After each install attempt, verify with `command -v vulnetix`. If all methods fail, inform the user:
> Vulnetix CLI could not be installed automatically. Install manually: `brew install vulnetix/tap/vulnetix` (macOS/Linux), `scoop install vulnetix` (Windows), or download from https://github.com/Vulnetix/cli/releases

**Abort the skill if the CLI cannot be made available.** Do not proceed with partial results.

### Step 1: Fetch Fix Data

Run the Vulnetix VDB fixes command for both V1 and V2 endpoints:

```bash
vulnetix vdb fixes "$ARGUMENTS" -o json | jq -f "${CLAUDE_PLUGIN_ROOT}/skills/_lib/jq/fixes.jq"
vulnetix vdb fixes "$ARGUMENTS" -o json -V v2 | jq -f "${CLAUDE_PLUGIN_ROOT}/skills/_lib/jq/fixes.jq"
```

**V1 response** (basic fixes):
```json
{
  "fixes": [
    {
      "type": "version",
      "package": "log4j-core",
      "ecosystem": "maven",
      "fixedIn": "2.17.1",
      "description": "Upgrade to patched version"
    }
  ]
}
```

**V2 response** (enhanced with registry, distro, source fixes):
```json
{
  "fixes": [
    {
      "type": "registry",
      "package": "log4j-core",
      "ecosystem": "maven",
      "fixedIn": "2.17.1",
      "registryUrl": "https://repo1.maven.org/...",
      "releaseDate": "2021-12-28"
    },
    {
      "type": "distro-patch",
      "distro": "ubuntu",
      "version": "20.04",
      "package": "liblog4j2-java",
      "patchVersion": "2.17.1-0ubuntu1",
      "aptCommand": "sudo apt-get install liblog4j2-java=2.17.1-0ubuntu1"
    },
    {
      "type": "source-fix",
      "commitUrl": "https://github.com/apache/logging-log4j2/commit/abc123",
      "patchUrl": "https://github.com/apache/logging-log4j2/commit/abc123.patch"
    }
  ]
}
```

### Step 2: Fetch Vulnerability Context

Get additional context about the vulnerability:

```bash
vulnetix vdb vuln "$ARGUMENTS" -o json | jq -f "${CLAUDE_PLUGIN_ROOT}/skills/_lib/jq/vuln.jq"
vulnetix vdb affected "$ARGUMENTS" -o json -V v2
```

Extract:
- **Affected package/product** names
- **Vulnerable version ranges** (e.g., `>=2.0.0, <2.17.1`)
- **CVSS/severity** (to assess urgency)
- **CISA KEV due date** (if applicable)

### Step 3: Analyze Repository Dependencies (Deep Filesystem Scan)

You MUST perform a thorough scan that goes beyond the current working directory. Search the entire project tree including gitignored directories.

#### 3a-pre: Check for Cached SBOMs

Before scanning, check the `manifests` section of `.vulnetix/memory.yaml` for recently scanned files. If a manifest was scanned by the pre-commit hook (or a prior skill invocation) within the last 24 hours (`last_scanned` timestamp), read the cached SBOM from `sbom_path` instead of re-scanning. This avoids redundant API calls. If the SBOM file is missing or stale, proceed with a fresh scan.

#### 3a: Find All Manifest and Lockfiles

Use **Glob** to find manifest files across the project, including monorepo structures:

```
**/package.json, **/package-lock.json, **/yarn.lock, **/pnpm-lock.yaml
**/requirements.txt, **/pyproject.toml, **/Pipfile, **/Pipfile.lock, **/poetry.lock, **/uv.lock
**/go.mod, **/go.sum
**/Cargo.toml, **/Cargo.lock
**/pom.xml, **/build.gradle, **/build.gradle.kts, **/gradle.lockfile
**/Gemfile, **/Gemfile.lock
**/composer.json, **/composer.lock
```

#### 3b: Derive Installed Versions from the Filesystem

**Do not rely solely on manifests.** Verify the actually-installed version by reading from package manager artifacts. These directories are typically gitignored — read them directly:

- **npm/node:** Read `node_modules/<package>/package.json` → `.version` field. Also check parent directories and workspace root `node_modules/`.
- **Python:** Run `pip show <package>` or read `.venv/lib/python*/site-packages/<package>/METADATA` or `__pycache__` dist-info directories.
- **Go:** Parse `go.sum` for exact hashes. Run `go list -m -json <package>` if go toolchain is available.
- **Rust:** Read `Cargo.lock` for exact resolved versions. Run `cargo metadata --format-version 1` if available.
- **Maven:** Check `~/.m2/repository/<groupPath>/<artifact>/` for cached JARs. Run `mvn dependency:tree` if available.
- **Ruby:** Read `Gemfile.lock` for resolved versions.
- **System binaries:** Run `which <binary>` then `<binary> --version` to determine installed version from `PATH`.

#### 3c: Determine Dependency Relationship

Use **Read** on each manifest and lockfile to determine:

1. **Is the vulnerable package installed?** (exact name match in manifest or lockfile)
2. **What version is installed?** (compare manifest, lockfile, AND filesystem-installed version — report all if they differ)
3. **Is it a direct or transitive dependency?** (present in manifest = direct; only in lockfile = transitive)
4. **What imports/requires are used from this package?** Use **Grep** to find all import/require/include statements referencing the vulnerable package across the codebase

If the package is **not found**, inform the user that the vulnerability may not affect this repository.

### Step 4: Evaluate Dependency Inlining (First-Party Replacement)

Before proposing a version bump, evaluate whether the dependency can be removed entirely:

**Criteria for inlining (ALL must be true):**
1. The affected third-party code is **open source** with a compatible license
2. The source is **publicly available online** (e.g., on GitHub, GitLab, crates.io source)
3. The portion of the library actually used by this application is **small** — assess by:
   - Counting how many functions/classes/modules from the package are imported
   - Estimating the lines of code for just those used parts (< ~200 lines is a good threshold)
4. The used functionality is **self-contained** (no deep internal dependency chain within the library)

**If inlining is viable:**
- Use **WebFetch** to retrieve the specific source file(s) from the upstream repository
- Extract only the functions/classes actually used by the application
- Preserve the original license attribution in a comment header
- Propose writing the extracted code as a first-party module (e.g., `lib/`, `internal/`, `utils/`)
- Show edits to update all import/require statements to point to the new first-party module
- Show edits to remove the dependency from all manifest and lockfiles

**Present this as Option A0 (highest priority) when the criteria are met,** above the standard Version Bump option.

### Step 5: Present Fix Options

Categorize fixes into 5 categories (A0-D) and present them in priority order. **Every option MUST include the Safe Harbour confidence score and all version details per the Mandatory Reporting Requirements above.**

---

#### **A0. Inline as First-Party Code** (Best — when viable)

If the inlining evaluation in Step 4 passed:

```
Package: <name>
Current Version: <version> (source: <version-source>)
Fix: Remove dependency entirely, inline <N> functions as first-party code
Safe Harbour: <score> (typically High — you own the code, no upstream risk)
License: <original license> (attribution preserved in source header)
```

**Action:** Write inlined module, update all imports, remove from manifests and lockfiles.

---

#### **A. Version Bump** (Preferred when inlining is not viable)

If a patched version is available in the registry:

| Current Version | Version Source | Target Version | Fix Source | Safe Harbour | Breaking Changes? | Manifest File |
|-----------------|---------------|----------------|------------|-------------|-------------------|---------------|
| 2.14.1 | Lockfile: pom.xml | 2.17.1 | Registry: Maven Central | 0.82 (Reasonable) | Minor API changes | pom.xml |

**Action:** Update dependency version in manifest file.

**Risk assessment:**
- **Patch version** (2.14.1 → 2.14.2): Low risk, backward compatible
- **Minor version** (2.14.x → 2.15.0): Medium risk, check changelog
- **Major version** (2.x → 3.0): High risk, breaking changes expected

---

#### **B. Patch** (Alternative)

If a source patch or distro patch is available:

| Patch Source | Type | Commit/Version | Safe Harbour | Applicability |
|--------------|------|----------------|-------------|---------------|
| GitHub commit `abc123` | Source fix | `abc123` | 0.55 (Reasonable) | Can be applied to local fork |
| Ubuntu 20.04 | Distro patch | `2.17.1-0ubuntu1` | 0.75 (Reasonable) | Only if running on Ubuntu |

**Action:** Download patch and apply to local dependency copy (advanced users only).

---

#### **C. Workaround** (Temporary Mitigation)

If no fix is available yet, provide temporary mitigations:

- **Configuration changes** (disable vulnerable feature, enable safeguards)
- **Input validation** (sanitize untrusted input)
- **Network isolation** (firewall rules, rate limiting)
- **IDS/IPS Snort rules** — fetch traffic filter rules to detect and block exploit traffic:
  ```bash
  vulnetix vdb traffic-filters "$ARGUMENTS" -o json
  ```
  If rules are returned, present them to the user with deployment guidance (Snort, Suricata, or compatible IDS/IPS). Display the `rawText` field for each rule so the user can copy them directly into their IDS configuration. Note the `signatureSeverity` and `confidence` of each rule.
- **Vendor-recommended workarounds** (from advisory)
- **Selective imports** — refactor imports to avoid loading the vulnerable code path (see Step 7)

**Action:** Apply configuration changes to relevant files. If Snort rules are available, present them prominently as an immediate network-level mitigation.

---

#### **D. Advisory Guidance** (Informational)

- **Vendor advisory links** (official fix documentation)
- **CISA KEV due date** (if listed, agencies must patch by this date)
- **Community discussion** (GitHub issues, Stack Overflow)

**Action:** No immediate action, but monitor for updates.

---

### Step 6: Apply Fixes Immediately

After presenting the options, **immediately begin applying the preferred fix** (do not wait for a planning interview unless the situation is ambiguous). Apply changes in this order:

#### 6a: Back Up Lockfiles and Manifests for Rollback

Before making any changes, preserve the current state so the user can roll back:

```bash
# Copy lockfiles and manifests to a backup location
cp package-lock.json package-lock.json.vulnetix-backup 2>/dev/null
cp yarn.lock yarn.lock.vulnetix-backup 2>/dev/null
cp pom.xml pom.xml.vulnetix-backup 2>/dev/null
# ... for each relevant file
```

Inform the user that backups have been created and how to restore them.

#### 6b: Update Package Manager Manifests

Use **Edit** to update version constraints in all affected manifest files. Handle version locking and conflicts:

- **npm:** If `package-lock.json` pins a conflicting version, update both `package.json` and consider running `npm install` to regenerate the lockfile
- **Python (pip):** Update `requirements.txt` version pins. If using `pip-compile` / `pip-tools`, update `.in` files
- **Python (poetry):** Update `pyproject.toml` version constraints
- **Go:** Update `go.mod` require directives
- **Rust:** Update `Cargo.toml` version constraints. Handle workspace-level version overrides in `[patch]` section
- **Maven:** Update `<version>` in `pom.xml`. Handle BOM (Bill of Materials) version management in parent POMs
- **Gradle:** Update version in `build.gradle` or version catalog

**Dependency resolution overrides:** When version conflicts exist (e.g., another dependency pins the vulnerable version), apply package manager-specific override mechanisms:
- **npm:** `overrides` field in `package.json`
- **yarn:** `resolutions` field in `package.json`
- **pnpm:** `pnpm.overrides` in `package.json`
- **pip:** constraint files or direct pins
- **Maven:** `<dependencyManagement>` section or `<exclusions>`
- **Cargo:** `[patch]` section in `Cargo.toml`

#### 6c: Refactor Imports to Minimize Attack Surface

Use **Grep** to find all import/require/include statements for the vulnerable package. Where possible, refactor to import only the specific submodules or functions needed rather than the entire package:

**JavaScript/TypeScript:**
```diff
- import lodash from 'lodash'
+ import get from 'lodash/get'
+ import set from 'lodash/set'
```

**Python:**
```diff
- import cryptography
+ from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
```

**Java:**
```diff
- import org.apache.commons.collections.*;
+ import org.apache.commons.collections.CollectionUtils;
```

**Go:**
```diff
// Go imports are already module-path scoped — check if a subpackage can be used instead
- import "github.com/example/biglib"
+ import "github.com/example/biglib/subpkg"
```

This reduces the attack surface by not loading vulnerable code paths that the application never uses.

#### 6d: Dry-Run Package Manager to Verify

After editing manifests, run the package manager in dry-run or check mode to verify the dependency resolution succeeds without actually modifying `node_modules/` or equivalents:

```bash
# npm
npm install --dry-run

# yarn
yarn install --check-files

# pnpm
pnpm install --dry-run

# pip
pip install --dry-run -r requirements.txt

# go
go mod tidy -v  # prints what it would change

# cargo
cargo check

# maven
mvn dependency:resolve -DdryRun

# composer
composer install --dry-run
```

If the dry run fails (e.g., version conflict, missing package), diagnose the issue and either:
1. Adjust version constraints to resolve the conflict
2. Apply a dependency override (see 6b)
3. Report the conflict to the user with suggested alternatives

If the dry run succeeds, inform the user that the fix resolves cleanly.

#### 6e: Restore on Failure

If any step fails and the fix cannot be completed, restore from backups:

```bash
mv package-lock.json.vulnetix-backup package-lock.json 2>/dev/null
# ... for each backed-up file
```

Inform the user what failed and why, and suggest alternative approaches.

### Step 7: Post-Fix Verification

After applying fixes:

1. **Run tests** (identify test command from manifest and run it):
```bash
npm test             # npm
pytest               # Python
go test ./...        # Go
cargo test           # Rust
mvn test             # Maven
```

2. **Re-scan for the vulnerability and persist the CycloneDX SBOM:**
```bash
mkdir -p .vulnetix/scans
vulnetix scan --file <manifest> -f cdx17 > .vulnetix/scans/<sanitized-manifest>.cdx.json
```
   - Use the same naming convention as the pre-commit hook: replace `/` with `--` in the manifest path
   - This overwrites any prior SBOM for the same manifest, so `.vulnetix/scans/` always has the latest scan
   - Update the `discovery.sbom` field in `.vulnetix/memory.yaml` to point to this file

3. **Report results** including all version details:
```
Fix Applied:
  Package: <name>
  Previous Version: <old> (source: <how determined>)
  New Version: <new> (source: <registry|distro|commit>)
  Safe Harbour: <score> (<tier> confidence)
  Verification: <scan passed|scan still flags|tests passed|tests failed>
  Rollback: <backup files created at ...>
```

If the scan still shows the vulnerability, explain that it may be a transitive dependency and suggest:
- Using dependency update tools (`npm audit fix`, `cargo update`, etc.)
- Manually updating the parent dependency that pulls in the vulnerable package
- Checking if a newer version of the parent dependency exists
- Applying dependency overrides (see Step 6b)

### Step 8: Update Vulnerability Memory

After **every** action in this skill — whether a fix was applied, the user made a decision, or new information was discovered — update `.vulnetix/memory.yaml`.

#### 8a: Create or Update the Entry

Use **Read** to load the current file (if it exists), then use **Write** to update it. If the file does not exist, create it with the `schema_version: 1` header.

**On first discovery** (no prior entry for this vuln ID):
```yaml
  <VULN_ID>:
    aliases: [<any known aliases from VDB response>]
    package: <package name>
    ecosystem: <ecosystem>
    discovery:
      date: "<current ISO 8601 UTC timestamp>"
      source: <manifest|lockfile|sbom|scan|user|hook>
      file: <file where found, or null>
      sbom: <.vulnetix/scans/<manifest>.cdx.json, or null>
    versions:
      current: "<detected version>"
      current_source: "<how version was determined>"
      fixed_in: "<patched version, or null>"
      fix_source: "<registry|distro|commit hash, or null>"
    severity: <critical|high|medium|low|unknown>
    safe_harbour: <0.00-1.00>
    status: under_investigation
    justification: null
    action_response: null
    decision:
      choice: investigating
      reason: "Discovered via /vulnetix:fix"
      date: "<current timestamp>"
    history:
      - date: "<current timestamp>"
        event: discovered
        detail: "Found <package>@<version> in <file>"
```

**On fix applied:**
- Set `status: fixed`, `decision.choice: fix-applied`
- Update `versions.current` to the new version
- Append to `history`: `event: fix-applied`, detail: what was done

**On user decision** (interpret user feedback using VEX semantics):
- User says "won't fix" / "accept the risk" → `status: affected`, `action_response: will_not_fix`, `decision.choice: risk-accepted`
- User says "doesn't affect us" → `status: not_affected`, `decision.choice: not-affected`, set appropriate `justification`
- User says "we'll fix this later" → `status: affected`, `action_response: will_fix`, `decision.choice: deferred`
- User says "we have a workaround" → `status: not_affected`, `justification: inline_mitigations_already_exist`, `decision.choice: mitigated`
- User says "need more info" → `status: under_investigation`, `decision.choice: investigating`
- Dependency was inlined as first-party → `status: fixed`, `decision.choice: inlined`
- User says "we removed it" / "disabled that feature" → `status: not_affected`, `justification: component_not_present`, `decision.choice: risk-avoided`
- User says "our WAF handles it" / "platform mitigates this" → `status: not_affected`, `justification: vulnerable_code_cannot_be_controlled_by_adversary`, `decision.choice: risk-transferred`
- Always record the user's actual words in `decision.reason`
- Always append the decision to `history`

#### 8b: Preserve Decision Context

When recording a user decision, always capture:
- **What the user said** (verbatim or close paraphrase) as the `reason`
- **The current timestamp** as the `date`
- **Any qualifying context** (e.g., "accepted risk because this is an internal tool" or "deferring until after the v2.0 release")

#### 8c: Persist Dependabot State

If Dependabot data was gathered in Step 0c, write it to the `dependabot` section of the memory entry:
- `alert_number`, `alert_state`, `alert_url`
- `dismiss_reason`, `dismiss_comment` (if dismissed)
- `pr_number`, `pr_state`, `pr_url`, `pr_latest_comment` (if a PR exists)
- `last_checked`: current timestamp

If a Dependabot alert state change resulted in a VEX status update (e.g., alert moved from `open` to `fixed`), append to `history`: `event: dependabot-sync`, detail: `"Dependabot alert #N: <old state> → <new state>"`

**Do NOT change `status` or `decision` based on Dependabot alone** if the user has already made a deliberate decision. Only auto-update status from Dependabot if:
- No prior user decision exists (i.e., `decision.choice` is `investigating`)
- The Dependabot state is more definitive (e.g., `fixed` or `dismissed` with a clear reason)

#### 8d: Persist Code Scanning (CodeQL) State

If CodeQL data was gathered in Step 0d, write it to the `code_scanning` section of the memory entry:
- `alerts[]`: each correlated alert with `alert_number`, `state`, `rule_id`, `rule_name`, `severity`, `dismissed_reason`, `dismissed_comment`, `dismissed_by`, `file_path`, `start_line`, `url`
- `tool`, `tool_version`: from the alert's `tool` field
- `last_checked`: current timestamp

If a CodeQL alert state changed since the last check, append to `history`: `event: codeql-sync`, detail: `"CodeQL alert #N (<rule_id>): <old state> → <new state>"`

**Auto-update rules** (same principle as Dependabot):
- Only auto-update `status`/`decision` from CodeQL if no prior user decision exists
- A CodeQL `fixed` state is strong evidence the code-level issue is resolved — note in history but let user confirm
- A CodeQL `dismissed` with `dismissed_comment` provides justification context — record it but don't override user decisions

#### 8e: Persist Secret Scanning State

If secret scanning data was gathered in Step 0e, write it to the `secret_scanning` section of the memory entry:
- `alerts[]`: each correlated alert with `alert_number`, `state`, `secret_type`, `secret_type_display`, `resolution`, `resolution_comment`, `resolved_by`, `validity`, `file_path`, `url`, `push_protection_bypassed`
- `last_checked`: current timestamp

If a secret scanning alert state changed, append to `history`: `event: secret-scanning-sync`, detail: `"Secret scanning alert #N (<secret_type>): <old state> → <new state>"`

If a previously active secret is now `inactive` (revoked), note this as positive progress. If a previously unknown secret is now `active`, flag urgently.

#### 8f: Handle Aliases

If the VDB response reveals that this vuln ID has aliases (e.g., a CVE maps to a GHSA, or vice versa), update the `aliases` list. When checking for prior entries in Step 0, always check both the primary ID and all known aliases.

#### 8g: Update Manifests Section

If any manifest files were scanned during this fix workflow (Step 3 or Step 7), update the `manifests` section of `.vulnetix/memory.yaml`:
- For each scanned manifest: set `last_scanned` to current timestamp, `vuln_count` to the result, `scan_source: fix`
- If a new CycloneDX SBOM was generated, set `sbom_generated: true` and update `sbom_path`
- If a manifest was discovered that isn't already tracked, add a new entry with its `path`, `ecosystem`, and scan metadata
- Do not remove manifest entries added by the hook or other skills — only update or add

#### 8h: Clean Output

After writing the memory file, confirm to the user:
```
Vulnerability memory updated: <VULN_ID> — <developer-friendly status> (<reason summary>)
GitHub security sync: Dependabot <state>, CodeQL <N alerts>, Secret scanning <N alerts>
```

