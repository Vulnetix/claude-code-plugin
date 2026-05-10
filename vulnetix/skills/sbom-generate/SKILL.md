---
name: sbom-generate
description: Generate CycloneDX and/or SPDX SBOMs for the repo. Optionally signs with cosign.
argument-hint: "[--format cyclonedx|spdx|both] [--sign] [--output PATH]"
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
triggers:
  - "sbom"
  - "cyclonedx"
  - "spdx"
  - "generate sbom"
chain:
  - compliance-report
  - vex-publish
outputBudget: short
cooldown: per-session
---

# Vulnetix SBOM Generate Skill

## Conventions

This skill follows [`_lib/contract.md`](../_lib/contract.md): the Vulnetix CLI is auto-installed by hooks, `.vulnetix/capabilities.yaml` is always present, every `vulnetix vdb` call is piped through a verified `jq` filter from [`_lib/jq/`](../_lib/jq/), independent calls run in parallel as concurrent Bash tool calls, and trailing follow-ups are limited to one line. See the contract for output style, memory write rules, and cooldowns.

## Step 1: Load capabilities

Read `.vulnetix/capabilities.yaml`. Use `binaries.cosign` to gate signing. If user asks for `--sign` without cosign, surface install hint and skip signing.

## Step 2: Generate

```bash
OUT="${OUTPUT_DIR:-.vulnetix/sboms/$(date -u +%Y%m%dT%H%M%SZ)}"
mkdir -p "$OUT"

if [[ "$FORMAT" == "cyclonedx" ]] || [[ "$FORMAT" == "both" ]]; then
    vulnetix scan -o json-cyclonedx > "$OUT/sbom.cdx.json"
fi

if [[ "$FORMAT" == "spdx" ]] || [[ "$FORMAT" == "both" ]]; then
    vulnetix license -o json-spdx > "$OUT/sbom.spdx.json"
fi
```

## Step 3: Optional sign

```bash
[[ "$SIGN" == "true" ]] && cosign sign-blob --yes "$OUT/sbom.cdx.json" --bundle "$OUT/sbom.cdx.json.sig.bundle"
```

## Step 4: Compose with detected SBOM tools (conditional)

If `binaries.syft: true`, also produce a syft SBOM for cross-validation:

```bash
syft "$(pwd)" -o cyclonedx-json > "$OUT/sbom.syft.cdx.json"
```

Surface the diff (component count delta) so the user can spot gaps.

## Step 5: Render

```
SBOM(s) generated:
- CycloneDX: <path>  (<N components>, <M deps>)
- SPDX: <path>
- Signature: <path|none>
- Cross-validated with: syft (delta: +3 components)
```

Suggest `/vulnetix:compliance-report` for a full compliance bundle, or `/vulnetix:vex-publish` to attach VEX.
