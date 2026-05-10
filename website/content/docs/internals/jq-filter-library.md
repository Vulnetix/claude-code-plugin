---
title: jq filter library
weight: 8
description: How Pix v1.4.0 routes every Vulnetix VDB call through a verified jq filter to keep LLM context small. Covers the library layout, verification workflow, and CLI quirks.
---

Pix v1.4.0 introduces a small library of `jq` filters at [`vulnetix/skills/_lib/jq/`](https://github.com/Vulnetix/pix-ai-coding-assistant/tree/main/vulnetix/skills/_lib/jq). Every skill that calls a VDB endpoint pipes the output through the matching filter so the LLM only sees the fields it actually needs.

## Why

A single `vulnetix vdb vuln CVE-2021-44228 -o json` call returns ~4 MB (an array of 20 container views in CVE5 format). `vulnetix vdb exploits CVE-2021-44228 -o json` returns ~12 MB (an array of 10,000+ exploit records). Feeding either raw to the LLM blows the context budget. Filtered:

| Endpoint | Raw | Filtered | Reduction |
|---|---|---|---|
| `vdb vuln` | 4.0 MB | 5 KB | 99.87% |
| `vdb exploits` | 12 MB | 2 KB | 99.99% |
| `vdb fixes` | 87 KB | 2 KB | 97.5% |
| `vdb sightings` | 294 KB | 0.7 KB | 99.8% |
| `vdb iocs get` | 70 KB | 2.4 KB | 96.5% |
| `vdb attack-techniques get` | 2.6 KB | 0.06 KB | 98% |
| `vdb packages search` | 7 KB | 1.2 KB | 78% |

## Library layout

One filter per VDB endpoint Pix consumes:

| File | Endpoint(s) | Verification |
|---|---|---|
| [`vuln.jq`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/skills/_lib/jq/vuln.jq) | `vdb vuln` | verified against CVE-2021-44228 |
| [`vulns.jq`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/skills/_lib/jq/vulns.jq) | `vdb vulns` | partial — re-verify on first use |
| [`fixes.jq`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/skills/_lib/jq/fixes.jq) | `vdb fixes` | verified |
| [`exploits.jq`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/skills/_lib/jq/exploits.jq) | `vdb exploits` | verified |
| [`sightings.jq`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/skills/_lib/jq/sightings.jq) | `vdb sightings` | verified |
| [`iocs.jq`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/skills/_lib/jq/iocs.jq) | `vdb iocs get` | verified |
| [`attack-techniques.jq`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/skills/_lib/jq/attack-techniques.jq) | `vdb attack-techniques get` | verified |
| [`kev.jq`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/skills/_lib/jq/kev.jq) | `vdb kev list/get` | verified |
| [`packages.jq`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/skills/_lib/jq/packages.jq) | `vdb packages search` | verified |
| [`versions.jq`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/skills/_lib/jq/versions.jq) | `vdb versions` | verified |
| [`purl.jq`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/skills/_lib/jq/purl.jq) | `vdb purl` | partial |
| [`remediation.jq`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/skills/_lib/jq/remediation.jq) | `vdb remediation plan -V v2` | partial |
| [`workarounds.jq`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/skills/_lib/jq/workarounds.jq) | `vdb workarounds -V v2` | partial |
| [`triage.jq`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/skills/_lib/jq/triage.jq) | `vdb triage` | partial |
| [`scorecard.jq`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/skills/_lib/jq/scorecard.jq) | `vdb scorecard -V v2` | partial |
| [`cwe.jq`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/skills/_lib/jq/cwe.jq) | `vdb cwe -V v2` | partial |
| [`ai-list.jq`](https://github.com/Vulnetix/pix-ai-coding-assistant/blob/main/vulnetix/skills/_lib/jq/ai-list.jq) | `vdb ai-discoveries`, `ai-in-wild`, `ai-malware`, `ai-assisted-exploits` | partial |

"Partial" filters are inferred from the vdb-api source struct definitions; they should be verified against the live response on first use and updated if the shape diverges.

## Standard skill invocation

```bash
vulnetix vdb vuln "$ARGUMENTS" -o json | jq -f "${CLAUDE_PLUGIN_ROOT}/skills/_lib/jq/vuln.jq"
```

## CLI quirks observed in v2.7.x

A handful of `vdb` subcommands treat `-o` as **output filename** (not format). Use `-o /dev/stdout` to pipe their output:

- `vdb sightings <id>`
- `vdb iocs get <id>`
- `vdb attack-techniques get <id>`
- `vdb kev list` / `vdb kev get`

Bare invocations of some subcommands return help text rather than data:

- `vdb iocs <id>` — needs `iocs get <id>` or `iocs list --cve-id <id>`.
- `vdb attack-techniques <id>` — needs `attack-techniques get <id>`.
- `vdb metrics <id>` — `metrics types` is the only subcommand; per-CVE metrics live in `vdb vuln`'s `containers.adp[0].x_*` blocks (use `vuln.jq`).

## Verification workflow

When adding a new filter or updating an existing one:

1. Read the response struct in [`/home/chris/GitHub/Vulnetix/vdb-api`](https://github.com/Vulnetix/vdb-api) for field-name hints.
2. Run the live CLI: `vulnetix vdb <cmd> <args> -o json > sample.json`. Pace one second between calls to avoid rate-limit retries.
3. Inspect actual shape: `jq -r 'if type == "array" then "array of \(length); first keys: \(.[0] | keys_unsorted)" else "object keys: \(keys_unsorted)" end' sample.json`.
4. Draft a filter that extracts only the fields a Pix skill cares about.
5. `cat sample.json | jq -f filter.jq | wc -c` — confirm valid output and meaningful reduction.
6. Save to `_lib/jq/<cmd>.jq` with a header comment listing fields, source-struct path, and the CVE / package fixture used.

## Filter design discipline

- Slice arrays (`.[0:N]`) for top-N projections.
- Truncate prose with `if length > N then .[:N-3] + "..." else . end`.
- Use `// null` or `// "n/a"` for missing fields so output is always valid JSON.
- Prefer object output (`{a, b, c}`) over re-keying when the result is a single record.
- Don't hand-construct CVSS — Vulnetix's `containers.adp[0].x_threatExposure` already provides a composite score with rule breakdown.
