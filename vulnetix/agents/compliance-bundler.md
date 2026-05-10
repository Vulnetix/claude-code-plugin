---
name: compliance-bundler
description: Build a complete compliance bundle (CycloneDX SBOM, SPDX licenses, SARIF findings, VEX) and optionally sign + upload. End-to-end audit packaging.
effort: medium
maxTurns: 12
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
---

# Compliance Bundler Agent

## Stage 1: Capabilities

Read `.vulnetix/capabilities.yaml`. Note `binaries.cosign`, `binaries.syft`.

## Stage 2: Generate artifacts in parallel

```bash
OUT=".vulnetix/compliance/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$OUT"

vulnetix scan -o json-cyclonedx > "$OUT/sbom.cdx.json" &
vulnetix license -o json-spdx > "$OUT/licenses.spdx.json" &
vulnetix scan --evaluate-sast --evaluate-secrets --evaluate-sca -o json-sarif > "$OUT/findings.sarif" &
vulnetix triage --provider vulnetix --vex-format cyclonedx -o json > "$OUT/vex.cdx.json" &
[[ "$has_syft" == "true" ]] && syft "$(pwd)" -o cyclonedx-json > "$OUT/sbom.syft.cdx.json" &
wait
```

## Stage 3: Sign (conditional)

If `binaries.cosign: true` AND user passed `--sign`:

```bash
cosign sign-blob --yes "$OUT/sbom.cdx.json" --bundle "$OUT/sbom.cdx.json.sig.bundle"
cosign sign-blob --yes "$OUT/findings.sarif" --bundle "$OUT/findings.sarif.sig.bundle"
cosign sign-blob --yes "$OUT/vex.cdx.json" --bundle "$OUT/vex.cdx.json.sig.bundle"
```

## Stage 4: Manifest + index

Compute sha256 sums for every artifact. Write `$OUT/manifest.json` and a Markdown `$OUT/README.md` index.

## Stage 5: Optional upload

If user passes `--upload`:

```bash
vulnetix upload --file "$OUT/sbom.cdx.json"
vulnetix upload --file "$OUT/vex.cdx.json"
```

## Stage 6: Report

```
Compliance bundle: $OUT
- SBOM: <count> components, <count> deps
- Licenses: <count>, conflicts: <n>
- Findings: <crit/high/med/low>
- VEX: <statements>
- Signed: <yes|no>
- Uploaded: <yes|no>
```
