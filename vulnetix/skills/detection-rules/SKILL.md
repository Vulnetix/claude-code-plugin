---
name: detection-rules
description: Fetch Snort, Suricata, YARA, and Nuclei detection content for a vulnerability. Filters rule families to the user's installed detection stack.
argument-hint: <vuln-id>
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
---

# Vulnetix Detection Rules Skill

Pulls IDS/IPS, malware-detection, and active-scan content for a CVE. Capability-aware: only fetches rule families the user can actually use.

## Step 1: Load capabilities

Read `.vulnetix/capabilities.yaml`. Capture `derived.detection_stack`. If empty, prompt:

```
No detection tooling found (snort, suricata, yara, nuclei, semgrep). I can still fetch the raw rules — proceed?
```

If the user accepts, treat the stack as `[snort, yara, nuclei]` for completeness. Otherwise abort with a one-liner pointing at install docs.

## Step 2: Fetch each available family

For each family in `detection_stack`:

```bash
# Snort/Suricata
vulnetix vdb snort-rules get "$ARGUMENTS" -o json
vulnetix vdb traffic-filters "$ARGUMENTS" -o json

# YARA
vulnetix vdb yara-rules get "$ARGUMENTS" -o json

# Nuclei
vulnetix vdb nuclei get "$ARGUMENTS" -o json
```

Skip families absent from `detection_stack` to avoid wasted API calls.

## Step 3: Save rule files (raw form)

Write rule content to `.vulnetix/detection/<VULN_ID>/`:
- `snort.rules` (concat of all Snort rule bodies)
- `suricata.rules` (if family present)
- `vuln.yar` (concat of YARA rules)
- `nuclei-<id>.yaml` (one per template)

Use `--format rules` / `--format yaml` against the same subcommand:

```bash
vulnetix vdb snort-rules list --cve-id "$ARGUMENTS" --format rules > .vulnetix/detection/$ARGUMENTS/snort.rules
vulnetix vdb yara-rules list --cve-id "$ARGUMENTS" --format rules > .vulnetix/detection/$ARGUMENTS/vuln.yar
vulnetix vdb nuclei get "$ARGUMENTS" --format yaml > .vulnetix/detection/$ARGUMENTS/nuclei.yaml
```

## Step 4: Render report

For each family, list:
- Rule count + highest signature severity
- File path on disk
- A copy-pasteable invocation hint based on installed binaries:
  - `snort -c snort.conf -A console` (only if `binaries.snort: true`)
  - `yara vuln.yar /path/to/scan` (only if `binaries.yara: true`)
  - `nuclei -t .vulnetix/detection/$ARGUMENTS/nuclei.yaml -u <target>` (only if `binaries.nuclei: true`)

## Step 5: Memory update

Append `event: detection-rules` with counts per family to the vuln entry.

## Notes

- This skill never executes rules. The user (or `/vulnetix:exploit-test`) runs them.
- Filter is honest: if YARA is missing, the YARA section is omitted from the report and from disk writes.
