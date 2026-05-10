---
name: compliance-report
description: Build a compliance bundle — CycloneDX SBOM, SPDX license report, SARIF findings, and (optionally) a signed attestation.
argument-hint: "[--sign] [--output-dir .vulnetix/compliance/]"
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
---

# Vulnetix Compliance Report Skill

Produces a bundle suitable for audit / attestation submission.

## Step 1: Load capabilities

Read `.vulnetix/capabilities.yaml`. Use `binaries.cosign` to gate the `--sign` step.

## Step 2: Generate artifacts in parallel

```bash
OUT="${OUTPUT_DIR:-.vulnetix/compliance/$(date -u +%Y%m%dT%H%M%SZ)}"
mkdir -p "$OUT"

vulnetix scan -o json-cyclonedx > "$OUT/sbom.cdx.json" &
vulnetix license -o json-spdx > "$OUT/licenses.spdx.json" &
vulnetix scan --evaluate-sast -o json-sarif > "$OUT/findings.sarif" &
wait
```

## Step 3: Generate VEX (uses local memory.yaml)

```bash
vulnetix triage --provider vulnetix --vex-format cyclonedx -o json > "$OUT/vex.cdx.json"
```

## Step 4: Sign (conditional)

If `--sign` and `binaries.cosign: true`:

```bash
cosign sign-blob --yes "$OUT/sbom.cdx.json" --bundle "$OUT/sbom.cdx.json.sig.bundle"
cosign sign-blob --yes "$OUT/findings.sarif" --bundle "$OUT/findings.sarif.sig.bundle"
```

If cosign absent and user requested `--sign`, surface install hint and continue without signatures.

## Step 5: Manifest

Write `$OUT/manifest.json` listing all artifacts with sha256 sums. Render Markdown index `$OUT/README.md`.

## Step 6: Render report

```
Compliance bundle: <path>
- SBOM (CycloneDX): <path/size/component count>
- Licenses (SPDX): <path/license count/conflict count>
- Findings (SARIF): <path/critical/high/medium count>
- VEX (CycloneDX): <path/statement count>
- Signed: <yes|no>  (cosign: <available|missing>)
```

Suggest next: `/vulnetix:vex-publish --upload` for VEX submission, or supply the path to your audit pipeline.
