---
title: Skills
weight: 4
description: LLM-guided interactive workflows that analyze vulnerabilities, assess risk, and propose remediation using AI.
---

Skills are LLM-guided interactive workflows invoked with `/vulnetix:<skill-name>`. Unlike [commands](/docs/commands) (which are deterministic CLI wrappers that run a subcommand and display output), skills involve **AI analysis** powered by the Claude Sonnet model. They interpret data, assess risk, correlate findings across sources, and produce rich Markdown output with tables and Mermaid diagrams.

Every skill:

- Reads and updates [`.vulnetix/memory.yaml`](/docs/data-structures/memory-yaml) to persist findings across sessions
- Cross-references CycloneDX SBOMs in `.vulnetix/scans/` when available
- Integrates with GitHub Advanced Security (Dependabot, CodeQL, Secret Scanning) when `gh` CLI is authenticated
- Suggests next steps by recommending other skills

## Capabilities awareness

As of v1.3.0, every skill consults [`.vulnetix/capabilities.yaml`](/docs/data-structures/capabilities-yaml) before invoking the Vulnetix CLI. The session-start [capabilities-detect](/docs/hooks/capabilities-detect) hook probes which security tools (`nuclei`, `snort`, `yara`, `semgrep`, `syft`, `grype`, `trivy`, `cosign`, `gh`, package managers) are callable AND which signals the repo carries (manifests, Dockerfiles, IaC, CI configs). Skills then narrow their CLI calls and external integrations to only what the user can act on.

## Skill Reference

### Foundational

| Skill | Invocation | Purpose |
|-------|-----------|---------|
| [Capabilities Detect](capabilities-detect) | `/vulnetix:capabilities-detect` | Re-probe system + repo signals; refresh `.vulnetix/capabilities.yaml` |
| [Dashboard](dashboard) | `/vulnetix:dashboard` | View all tracked vulnerabilities and status |

### Core vulnerability intelligence

| Skill | Invocation | Purpose |
|-------|-----------|---------|
| [Vulnerability Lookup](vuln) | `/vulnetix:vuln <id-or-package>` | Look up a vulnerability or list package vulns |
| [Package Search](package-search) | `/vulnetix:package-search <name>` | Search packages and assess security risk |
| [Exploit Analysis](exploits) | `/vulnetix:exploits <vuln-id>` | Analyze exploit intelligence and threat model |
| [Exploits Search](exploits-search) | `/vulnetix:exploits-search [flags]` | Search for exploited vulnerabilities |
| [Fix Intelligence](fix) | `/vulnetix:fix <vuln-id>` | Get fix intelligence and apply remediation |
| [Remediation Planning](remediation) | `/vulnetix:remediation <vuln-id>` | Context-aware remediation plan |

### SOC / IR

| Skill | Invocation | Purpose |
|-------|-----------|---------|
| [SOC Triage](soc-triage) | `/vulnetix:soc-triage [flags]` | Daily prioritized SOC pull intersected with this repo |
| [IOC Pivot](ioc-pivot) | `/vulnetix:ioc-pivot <vuln-id>` | IOCs + sightings timeline; optional STIX export |
| [Detection Rules](detection-rules) | `/vulnetix:detection-rules <vuln-id>` | Snort/YARA/Nuclei content for a CVE |
| [ATT&CK Mapping](attack-mapping) | `/vulnetix:attack-mapping [vuln-id\|--all-tracked]` | MITRE ATT&CK technique view |
| [KEV Watch](kev-watch) | `/vulnetix:kev-watch [flags]` | CISA/EU KEV intersected with installed deps |
| [Threat Feed](threat-feed) | `/vulnetix:threat-feed` | Daily threat-intel digest |
| [Incident Respond](incident-respond) | `/vulnetix:incident-respond <vuln-id>` | End-to-end IR playbook |
| [Verify Fix](verify-fix) | `/vulnetix:verify-fix <vuln-id>` | Confirm a fix landed (gated scan + targeted recheck) |
| [Exploit Test](exploit-test) | `/vulnetix:exploit-test <vuln-id> [--target URL]` | Generate a runnable exploit-validation command |
| [VEX Publish](vex-publish) | `/vulnetix:vex-publish [flags]` | Generate + optionally upload OpenVEX/CycloneDX VEX |
| [Compliance Report](compliance-report) | `/vulnetix:compliance-report [flags]` | SBOM + SPDX + SARIF + VEX bundle |

### SecDev / shift-left

| Skill | Invocation | Purpose |
|-------|-----------|---------|
| [SAST Scan](sast-scan) | `/vulnetix:sast-scan [flags]` | Run SAST against changed files; augment with local Semgrep |
| [Secret Scan](secret-scan) | `/vulnetix:secret-scan [flags]` | Detect hardcoded secrets |
| [Container Scan](container-scan) | `/vulnetix:container-scan [flags]` | Dockerfile/Containerfile + optional Trivy/Grype/Syft |
| [IaC Scan](iac-scan) | `/vulnetix:iac-scan [flags]` | Terraform/OpenTofu/Nix/k8s misconfig detection |
| [License Check](license-check) | `/vulnetix:license-check [flags]` | License conflicts + policy enforcement |
| [Dep-Add Guard](dep-add-guard) | `/vulnetix:dep-add-guard <package>` | Risk gate before adding a dependency |
| [Dep Resolve](dep-resolve) | `/vulnetix:dep-resolve <package>` | Resolve version conflicts blocking a fix |
| [Safe Version](safe-version) | `/vulnetix:safe-version <package>` | Newest safe version under a major-bump cap |
| [EOL Check](eol-check) | `/vulnetix:eol-check [--strict]` | End-of-life runtimes/packages |
| [Typosquat Check](typosquat-check) | `/vulnetix:typosquat-check [package\|--installed]` | Malware / typosquat detection |
| [Code Review (Security)](code-review-security) | `/vulnetix:code-review-security [--pr N]` | Unified PR security review |
| [Secure Code Write](secure-code-write) | `/vulnetix:secure-code-write [topic]` | Proactive coding guidance |
| [SBOM Generate](sbom-generate) | `/vulnetix:sbom-generate [flags]` | CycloneDX/SPDX SBOMs with optional cosign |

## Skills vs Commands

| | Skills | Commands |
|---|--------|----------|
| **Model** | Claude Sonnet (LLM analysis) | None (deterministic) |
| **Output** | Interpreted assessments, tables, Mermaid diagrams | Raw structured data |
| **Memory** | Reads and updates `.vulnetix/memory.yaml` | No memory interaction |
| **GHAS integration** | Dependabot, CodeQL, Secret Scanning | None |
| **Interactivity** | May ask follow-up questions, propose edits | Display only |
| **Use case** | Risk assessment, remediation planning, threat modeling | Quick data lookups, scripting |

## Invocation

All skills use the colon syntax:

```
/vulnetix:<skill-name> <arguments>
```

For example:

```
/vulnetix:exploits CVE-2021-44228
/vulnetix:package-search express
/vulnetix:vuln lodash
```
