---
title: Data Structures
weight: 7
description: The .vulnetix/ directory and its contents -- memory files, SBOMs, and PoC source caches.
---

The Vulnetix Claude Code Plugin stores all local state in a `.vulnetix/` directory at the root of your repository. This directory is auto-created by hooks and skills on first use and is automatically added to `.gitignore` so it is never committed.

## Directory Layout

```
.vulnetix/
  capabilities.yaml    # System binaries + repo signals (refreshed every 24h)
  memory.yaml          # Vulnerability state and tracking
  scans/               # Package search results and CycloneDX SBOM files
    *.packages.json    # Pre-commit package search results
    *.cdx.json         # Post-install CycloneDX SBOMs
  detection/           # Snort/YARA/Nuclei content fetched per CVE
    <VULN_ID>/
      snort.rules
      vuln.yar
      nuclei.yaml
  iocs/                # STIX 2.1 bundles for SOAR/SIEM ingestion
  vex/                 # OpenVEX / CycloneDX VEX statements
  compliance/          # Bundled SBOM+SPDX+SARIF+VEX for audit
  review/              # PR security review artifacts
  sboms/               # SBOM-only generation outputs
  upgrade/             # Dep-upgrade orchestrator queue + state
  pocs/                # Exploit proof-of-concept source cache
    <VULN_ID>/
      ...
```

## Key Properties

**Auto-created.** The `.vulnetix/` directory and its subdirectories are created automatically the first time a hook or skill runs. You never need to create them manually.

**Auto-ignored.** On creation, the directory is added to your repository's `.gitignore` file (creating the file if it does not exist). The contents are local to your machine and should never be committed.

**Never committed.** All data in `.vulnetix/` is local working state -- package search results, SBOMs, vulnerability memory, and cached PoC source files. None of it belongs in version control.

**Legacy migration.** If a `.vulnetix-memory.yaml` file exists at the repository root (the pre-directory layout), the pre-commit hook automatically migrates it to `.vulnetix/memory.yaml` on first run.

## Contents

{{< cards >}}
  {{< card link="capabilities-yaml" title="capabilities.yaml" subtitle="System binaries + repo signals (read by every Pix surface)." >}}
  {{< card link="memory-yaml" title="memory.yaml" subtitle="Vulnerability tracking state, decisions, and history." >}}
  {{< card link="sboms" title="Scan Results" subtitle="Package search results and CycloneDX v1.7 SBOM files." >}}
  {{< card link="pocs" title="PoC Source Cache" subtitle="Cached exploit proof-of-concept source files." >}}
{{< /cards >}}
