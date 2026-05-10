---
title: Commands
weight: 5
description: Deterministic CLI wrappers that run vulnetix vdb subcommands directly with no LLM analysis.
---

Commands are thin, deterministic wrappers around `vulnetix vdb` subcommands. Unlike [skills](/docs/skills) or [agents](/docs/agents), commands involve **no LLM analysis** -- they execute the CLI, capture the JSON output, and display it in a structured format.

Use commands when you want raw VDB data without interpretation, or when you need to pipe exact output into another workflow.

## Command Reference

### VDB lookups

| Command | Wraps | Purpose |
|---------|-------|---------|
| [vdb-vuln](vdb-vuln) | `vulnetix vdb vuln` | Look up a vulnerability by ID |
| [vdb-vulns](vdb-vulns) | `vulnetix vdb vulns` | List vulnerabilities for a package |
| [vdb-affected](vdb-affected) | `vulnetix vdb affected -V v2` | Affected products/packages |
| [vdb-advisories](vdb-advisories) | `vulnetix vdb advisories -V v2` | Advisory data |
| [vdb-fixes](vdb-fixes) | `vulnetix vdb fixes` | Fix data (patches, advisories, distro) |
| [vdb-workarounds](vdb-workarounds) | `vulnetix vdb workarounds -V v2` | Workaround intelligence |
| [vdb-remediation](vdb-remediation) | `vulnetix vdb remediation plan -V v2` | Context-aware remediation plan |
| [vdb-scorecard](vdb-scorecard) | `vulnetix vdb scorecard -V v2` | Vulnerability scorecard |
| [vdb-cwe](vdb-cwe) | `vulnetix vdb cwe -V v2` | CWE intelligence |
| [vdb-metrics](vdb-metrics) | `vulnetix vdb metrics` | CVSS/EPSS metrics |
| [vdb-vex](vdb-vex) | `vulnetix vdb vex` | VEX statements |
| [vdb-purl](vdb-purl) | `vulnetix vdb purl` | Lookup by Package URL |
| [vdb-versions](vdb-versions) | `vulnetix vdb versions` | All versions across ecosystems |
| [vdb-product](vdb-product) | `vulnetix vdb product` | Product version info |
| [vdb-ecosystem](vdb-ecosystem) | `vulnetix vdb ecosystem` | Ecosystem-scoped lookups |
| [vdb-packages](vdb-packages) | `vulnetix vdb packages search` | Package search |

### Exploit + threat intel

| Command | Wraps | Purpose |
|---------|-------|---------|
| [vdb-exploits-search](vdb-exploits-search) | `vulnetix vdb exploits search` | Search exploited vulns |
| [vdb-ai-discoveries](vdb-ai-discoveries) | `vulnetix vdb ai-discoveries` | AI-discovered vulns |
| [vdb-ai-in-wild](vdb-ai-in-wild) | `vulnetix vdb ai-in-wild` | AI-discovered in-the-wild observations |
| [vdb-ai-malware](vdb-ai-malware) | `vulnetix vdb ai-malware` | AI malware family intelligence |
| [vdb-ai-assisted-exploits](vdb-ai-assisted-exploits) | `vulnetix vdb ai-assisted-exploits` | AI-assisted exploit demos |
| [vdb-iocs](vdb-iocs) | `vulnetix vdb iocs` | IOC pivots (CrowdSec + Shadowserver) |
| [vdb-sightings](vdb-sightings) | `vulnetix vdb sightings` | Merged in-the-wild timeline |
| [vdb-attack-techniques](vdb-attack-techniques) | `vulnetix vdb attack-techniques` | MITRE ATT&CK mappings |
| [vdb-kev](vdb-kev) | `vulnetix vdb kev` | KEV catalogue |
| [vdb-triage](vdb-triage) | `vulnetix vdb triage` | Score-driven triage feed |
| [vdb-exploit-trends](vdb-exploit-trends) | `vulnetix vdb exploit-trends` | Severity-tier signal counts |
| [vdb-vendor-trends](vdb-vendor-trends) | `vulnetix vdb vendor-trends` | Vendor monthly/yearly breakdown |
| [vdb-timeline](vdb-timeline) | `vulnetix vdb timeline` | Vuln lifecycle timeline |

### Detection + reporting

| Command | Wraps | Purpose |
|---------|-------|---------|
| [vdb-snort-rules](vdb-snort-rules) | `vulnetix vdb snort-rules` | Snort detection rules |
| [vdb-yara-rules](vdb-yara-rules) | `vulnetix vdb yara-rules` | YARA static-analysis rules |
| [vdb-nuclei](vdb-nuclei) | `vulnetix vdb nuclei` | Nuclei templates |
| [vdb-traffic-filters](vdb-traffic-filters) | `vulnetix vdb traffic-filters` | IDS/IPS traffic filter rules |
| [vdb-msrc](vdb-msrc) | `vulnetix vdb msrc` | Microsoft Patch Tuesday rollups |
| [vdb-cloud-locators](vdb-cloud-locators) | `vulnetix vdb cloud-locators -V v2` | Cloud resource locators |
| [vdb-summary](vdb-summary) | `vulnetix vdb summary` | Global VDB stats |
| [vdb-sources](vdb-sources) | `vulnetix vdb sources` | Vuln data sources |
| [vdb-ids](vdb-ids) | `vulnetix vdb ids` | CVE IDs published in a calendar month |
| [vdb-search](vdb-search) | `vulnetix vdb search` | Search CVE IDs by prefix |
| [vdb-gcve](vdb-gcve) | `vulnetix vdb gcve` | CVEs by date range |
| [vdb-raw](vdb-raw) | `vulnetix vdb raw` | Replay raw archived advisory bytes |
| [vdb-spec](vdb-spec) | `vulnetix vdb spec` | OpenAPI specification |
| [vdb-status](vdb-status) | `vulnetix vdb status` | API health + CLI metadata |
| [vdb-cache](vdb-cache) | `vulnetix vdb cache` | Manage local response cache |

### Local scanners

| Command | Wraps | Purpose |
|---------|-------|---------|
| [scan](scan) | `vulnetix scan` | Full scan (configurable across SCA/SAST/secrets/license/container/IaC) |
| [sast](sast) | `vulnetix sast` | SAST only |
| [sca](sca) | `vulnetix sca` | SCA only |
| [secrets](secrets) | `vulnetix secrets` | Secret detection only |
| [containers](containers) | `vulnetix containers` | Container/Dockerfile analysis |
| [iac](iac) | `vulnetix iac` | Terraform/OpenTofu/Nix |
| [license](license) | `vulnetix license` | License conflicts |
| [triage](triage) | `vulnetix triage` | Triage from GitHub or Vulnetix VDB |

### Artifact upload + auth + meta

| Command | Wraps | Purpose |
|---------|-------|---------|
| [upload](upload) | `vulnetix upload` | Upload SBOM / SARIF / VEX / SPDX / CSAF |
| [gha-upload](gha-upload) | `vulnetix gha upload` | Batch upload from GitHub Actions |
| [gha-status](gha-status) | `vulnetix gha status` | Poll GitHub Actions artifact status |
| [auth-login](auth-login) | `vulnetix auth login` | Interactive auth |
| [auth-status](auth-status) | `vulnetix auth status` | Auth status |
| [env](env) | `vulnetix env` | Current environment context |
| [version](version) | `vulnetix version` | CLI version |

## Invocation

All commands use the colon syntax:

```
/vulnetix:<command-name> <arguments>
```

For example:

```
/vulnetix:vdb-vuln CVE-2021-44228
```

Commands are marked `disable-model-invocation: true`, meaning your coding agent will never call them autonomously -- they only run when you invoke them explicitly.

## Output

Every command appends `-o json` to the underlying CLI call and parses the JSON response into a human-readable summary. The raw JSON is always available in the command output if you need it for scripting or further processing.
