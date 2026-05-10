# Pix Skill Contract — shared conventions

Every Pix skill, hook, command, and agent inherits the conventions in this document. Skill bodies should not recapitulate them. Reference this file by name (`See _lib/contract.md`) instead.

---

## 1. CLI availability

The Vulnetix CLI is the only required external binary. Hooks ship `hooks/ensure-vulnetix-cli.sh`, which finds an existing install or installs via brew → scoop → nix → GitHub releases → `go install`. Skills do **not** need to repeat install instructions — the user's shell almost always has `vulnetix` on PATH after the first session.

If a skill needs to verify, one line is enough:

```bash
command -v vulnetix &>/dev/null || { echo "Vulnetix CLI not found"; exit 1; }
```

---

## 2. Capabilities

`.vulnetix/capabilities.yaml` is always present (the SessionStart `capabilities-detect` hook populates it). Skills read fields directly:

| Field | Used for |
|---|---|
| `derived.primary_package_manager` | choose lockfile/manifest parsing |
| `derived.detection_stack` | filter rule families (snort/yara/nuclei/semgrep) |
| `derived.sbom_stack` | compose with syft/grype/trivy/cosign |
| `derived.has_containers` / `has_iac` / `has_ci` | gate scanner subsystems |
| `derived.soar` | `stix` → emit STIX bundles for IOC pivots |
| `derived.auth_status` | warn on `unauthenticated` or skip authenticated-only endpoints |
| `binaries.<name>` | gate any compose-with-tool integration |

Skills do not need to force a refresh; if something looks stale, `${CLAUDE_PLUGIN_ROOT}/hooks/capabilities-detect.sh` is callable, or `VULNETIX_FORCE_DETECT=1`.

---

## 3. JSON extraction is mandatory

Raw VDB responses are large (a single `vulnetix vdb vuln <id> -o json` is ~4 MB; `vulnetix vdb exploits` is ~12 MB). Skills **must not** pipe raw JSON to the LLM.

Every CLI call goes through a verified `jq` pipeline. The library lives at `vulnetix/skills/_lib/jq/<endpoint>.jq` and each filter is verified against live CLI output before being committed.

**Standard invocation form:**

```bash
vulnetix vdb vuln "$ARGUMENTS" -o json | jq -f "${CLAUDE_PLUGIN_ROOT}/skills/_lib/jq/vuln.jq"
```

**Output behavior caveats** (CLI quirks observed in v2.7.x):

- Most subcommands: `-o json` = output format (JSON to stdout).
- A few subcommands (sightings, attack-techniques get, kev list, iocs get) treat `-o` as **output filename**. Use `-o /dev/stdout` (or `--output json` explicitly + read from where it lands) to get stdout JSON.
- Always wrap with `2>/dev/null` to suppress progress lines; surface only the filtered JSON.

**Filter discipline:**

- Only extract fields the skill actually needs.
- Slice arrays (`.[0:N]`) for top-N projections.
- Truncate prose with `if length > N then .[:N-3] + "..." else . end`.
- Use `// null` / `// "n/a"` for missing fields so output is always valid JSON.
- Prefer `{a, b, c}` object output over re-keying when the result is a single record.

**When in doubt, the existing filter library `_lib/jq/*.jq` is the source of truth.** Don't write ad-hoc filters in skill bodies.

---

## 4. Parallelism

Independent VDB calls **must** be invoked as concurrent Bash tool calls in a single LLM message — not sequentially. SKILL bodies that need parallelism include this header:

> **Parallel block** — issue these as concurrent Bash tool calls in a single message:

…followed by the list. The harness already supports parallel tool execution; the LLM just needs the cue.

Sequential calls are appropriate when the second call depends on a value from the first.

---

## 5. Output style

- Markdown is the only format. The harness renders it; the LLM does **not** need a "Render report" step.
- Default output budget: **short** (≤ 30 lines). Skills declaring `outputBudget: medium` may go to 80 lines; `long` is unbounded.
- Mermaid diagrams are allowed when they add genuine value (timelines, distributions, kill-chain flows). Skip them for simple data.
- Tables for ranked / scored data; bullet lists for unordered findings.
- Suggest next steps in **one** trailing line: `Next: \`/vulnetix:verify-fix CVE-…\`` — not a multi-step playbook.

---

## 6. Memory writes

`.vulnetix/memory.yaml` is the persistent state file. Skills write to it **only** when they make a durable decision the user would expect to retrieve later:

- `vuln`, `exploits`, `fix`, `package-search` write per-vuln entries (existing behavior).
- Read-only skills (`soc-triage`, `kev-watch`, `threat-feed`, `attack-mapping`, `safe-version`, `dashboard`) do **not** write.
- Mutating skills (`fix`, `dep-resolve`, `verify-fix`) write a `history` event with the action taken.
- All multi-step skills with internal CLI calls pass `--disable-memory` on the inner calls to avoid race conditions; the orchestrating skill does one consolidated write at the end.

Memory schema is versioned (`schema_version: 1`) and unchanged in v1.4.0.

---

## 7. Cooldowns

Hooks and follow-up suggestions are gated by `vulnetix/hooks/_lib/cooldown.sh`. The hook scripts source it and call:

```bash
already_emitted "<key>" && exit 0
record_emission "<key>"
```

Markers live at `/tmp/vulnetix-cd-${PPID}.txt` and reset per session. Skills with `cooldown: per-session` in frontmatter respect the same gate when emitting trailing suggestions.

---

## 8. Frontmatter contract

Every SKILL.md and HOOK.md should declare:

```yaml
---
name: <kebab-case>
description: <≤80 chars, action-oriented>
argument-hint: <user-facing arg shape> # SKILL only
user-invocable: true                    # SKILL only
allowed-tools: Bash, Read, Glob, Grep   # tightened — Edit/Write only when mutating
model: sonnet | haiku                    # haiku for trivial dispatchers
triggers:                                # phrases the prompt-router matches
  - "<keyword phrase>"
  - "<keyword phrase>"
chain:                                   # typical next-skill suggestions
  - <skill-name>
  - <skill-name>
outputBudget: short | medium | long       # default short
cooldown: per-session                     # apply to hooks/skills emitting suggestions
---
```

`triggers:` is a list of natural-language phrases (lowercase, no anchors). The `prompt-router` hook reads them across all skills at startup and matches user prompts against them.

`chain:` lists the typical follow-up skills. Skills should suggest at most one chain item in their output.

`outputBudget:` is a soft contract; the LLM should aim for the budget but is not blocked from exceeding it when the user asks for more detail.

`cooldown:` defaults to absent (always emit). `per-session` means "skip if the same suggestion already fired this session."

---

## 9. Verification

Before adding a new filter or changing an existing one, run the live CLI command, capture sample JSON, pipe through the filter, confirm valid output and meaningful size reduction. Filters that cannot be verified against live data are not committed.
