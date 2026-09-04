---
title: capabilities.yaml
weight: 4
description: Schema for .vulnetix/capabilities.yaml — the file every Pix surface reads to scope which Vulnetix CLI features and external integrations are meaningful for the current system + repo.
---

`.vulnetix/capabilities.yaml` is written by `vulnetix agent capabilities`, refreshed when older than a day. It records which security tools are callable on this system and which signals the repository carries, plus a short `derived` block each skill and hook reads to scope its output — no Snort binary, no Snort output.

Detection was a shell hook until it moved into the CLI, which is also when it started being correct: the old detector tested for the `.github/workflows` **directory**, so a repository with an empty one reported CI it did not have, and it reported `auth_status: unauthenticated` for an authenticated CLI. It now runs on native Windows too.

## Schema

```yaml
schema_version: 1
detected_at: "2026-05-10T11:24:05Z"

binaries:
  vulnetix: true
  nuclei: true
  snort: false
  suricata: false
  yara: false
  semgrep: false
  syft: true
  grype: true
  trivy: false
  cosign: true
  docker: false
  podman: true
  gh: true
  git: true
  jq: true
  yq: false
  uv: true
  python: true
  python3: true
  node: true
  npm: true
  pnpm: true
  yarn: true
  pip: false
  pipx: false
  go: true
  cargo: true
  mvn: false
  gradle: false
  composer: false
  bundler: false
  dotnet: false
  terraform: true
  tofu: false
  kubectl: false
  helm: false
  brew: true
  scoop: false
  nix: false
  curl: true
  wget: true

repo:
  package_json: true
  package_lock: true
  pnpm_lock: false
  yarn_lock: false
  requirements: false
  pyproject: false
  uv_lock: false
  pipfile_lock: false
  poetry_lock: false
  go_mod: false
  cargo_toml: false
  pom_xml: false
  gradle: false
  composer: false
  gemfile_lock: false
  csproj: false
  dockerfile: true
  containerfile: false
  compose: false
  docker_compose: false
  terraform: false
  opentofu: false
  flake_nix: false
  gh_workflows: true
  gitlab_ci: false
  semgrep_config: false
  snort_rules: false
  yara_rules_yar: false
  yara_rules_yara: false

derived:
  primary_package_manager: npm
  has_containers: true
  has_iac: false
  has_ci: true
  detection_stack: ["nuclei"]
  sbom_stack: ["syft", "grype", "cosign"]
  soar: none
  auth_status: ok
```

## Field reference

### `binaries.*`

`true` if the binary is callable on `$PATH` at the time of detection. Skills/hooks gate features on these (e.g. `/vulnetix:detection-rules` only writes a YARA file when `binaries.yara: true`).

### `repo.*`

`true` if at least one matching file is present within four directory levels from the repo root (excluding `.git`, `node_modules`, `.vulnetix`).

### `derived.primary_package_manager`

The ecosystem most likely in use, inferred from the highest-priority lockfile/manifest present. Values: `npm`, `pnpm`, `yarn`, `uv`, `poetry`, `pipenv`, `pip`, `go`, `cargo`, `maven`, `gradle`, `composer`, `bundler`, `dotnet`, `unknown`.

### `derived.has_containers` / `has_iac` / `has_ci`

Boolean rollups derived from `repo.*` fields. Skills consult these to skip whole scanner subsystems when there's nothing to scan.

### `derived.detection_stack`

Array of detection-rule families the system has tools for: any subset of `snort`, `suricata`, `yara`, `nuclei`, `semgrep`. `/vulnetix:detection-rules` and `/vulnetix:incident-respond` only fetch families listed here.

### `derived.sbom_stack`

Array of SBOM/cosign tooling present: any subset of `syft`, `grype`, `trivy`, `cosign`. `/vulnetix:sbom-generate` and `/vulnetix:compliance-report` compose with these when present.

### `derived.soar`

Heuristic for SIEM/SOAR sink: `stix` or `none`. When `stix`, `/vulnetix:ioc-pivot` writes a STIX 2.1 bundle by default.

### `derived.auth_status`

Result of `vulnetix auth status -o json`: `ok` (authenticated), `unauthenticated`, or `unknown`. Surfaces gate against API rate limits accordingly.

## Refresh policy

- Auto-refreshes on session start if older than 24h.
- Force a refresh with `vulnetix agent capabilities --force`.
- The PostToolUse manifest-edit hook can also trigger a re-detect when manifests change.

## Why this exists

Vulnetix CLI exposes a vast surface (16 top-level commands, 47 `vdb` subcommands, dozens of output formats including Snort/YARA/Nuclei/STIX/CycloneDX/SPDX/SARIF). Naively invoking everything for every prompt would be slow, noisy, and produce output the user can't act on. `capabilities.yaml` is the single source of truth that lets each Pix surface ask: "is this user's system + repo even capable of acting on this output?" — and skip the call when the answer is no.
