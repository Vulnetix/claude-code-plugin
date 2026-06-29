#!/usr/bin/env bash
set -uo pipefail

# Capabilities detector — probes callable binaries and repo signals so
# downstream skills/hooks/commands/agents only invoke the parts of the
# Vulnetix CLI surface that are actually meaningful for this system+repo.
# Writes to .vulnetix/capabilities.yaml. Always exits 0.

if ! command -v jq &>/dev/null; then
    exit 0
fi

VULNETIX_DIR=".vulnetix"
CAP_FILE="${VULNETIX_DIR}/capabilities.yaml"
STAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Skip re-detection if file is fresh (<24h) unless caller forced it
if [[ -f "$CAP_FILE" ]] && [[ "${VULNETIX_FORCE_DETECT:-}" != "1" ]]; then
    if find "$CAP_FILE" -mmin -1440 2>/dev/null | grep -q .; then
        exit 0
    fi
fi

mkdir -p "$VULNETIX_DIR" 2>/dev/null

# --- Binary probes ---
BINARIES=(
    vulnetix nuclei snort suricata yara semgrep syft grype trivy cosign
    docker podman gh git jq yq uv python python3 node npm pnpm yarn pip pipx
    go cargo mvn gradle composer bundler dotnet terraform tofu kubectl helm
    brew scoop nix curl wget
)

bin_block=""
for b in "${BINARIES[@]}"; do
    if command -v "$b" &>/dev/null; then
        bin_block="${bin_block}  ${b}: true
"
    else
        bin_block="${bin_block}  ${b}: false
"
    fi
done

# --- Repo signals (depth-limited Globs) ---
declare -A REPO_SIGNALS=(
    [package_json]="package.json"
    [package_lock]="package-lock.json"
    [pnpm_lock]="pnpm-lock.yaml"
    [yarn_lock]="yarn.lock"
    [requirements]="requirements*.txt"
    [pyproject]="pyproject.toml"
    [uv_lock]="uv.lock"
    [pipfile_lock]="Pipfile.lock"
    [poetry_lock]="poetry.lock"
    [go_mod]="go.mod"
    [cargo_toml]="Cargo.toml"
    [pom_xml]="pom.xml"
    [gradle]="build.gradle*"
    [composer]="composer.json"
    [gemfile_lock]="Gemfile.lock"
    [csproj]="*.csproj"
    [dockerfile]="Dockerfile"
    [containerfile]="Containerfile"
    [compose]="compose.y*ml"
    [docker_compose]="docker-compose.y*ml"
    [terraform]="*.tf"
    [opentofu]="*.tofu"
    [flake_nix]="flake.nix"
    [gh_workflows]=".github/workflows/*.yml"
    [gitlab_ci]=".gitlab-ci.yml"
    [semgrep_config]=".semgrep*"
    [snort_rules]="*.rules"
    [yara_rules_yar]="*.yar"
    [yara_rules_yara]="*.yara"
)

repo_block=""
for key in "${!REPO_SIGNALS[@]}"; do
    pattern="${REPO_SIGNALS[$key]}"
    # Search up to 3 levels deep, exclude .git and node_modules
    found=$(find . -maxdepth 4 \( -path './.git' -o -path './node_modules' -o -path './.vulnetix' \) -prune -o -name "$pattern" -print 2>/dev/null | head -1)
    if [[ -n "$found" ]]; then
        repo_block="${repo_block}  ${key}: true
"
    else
        repo_block="${repo_block}  ${key}: false
"
    fi
done

has() {
    echo "$repo_block" | grep -q "  $1: true"
}
has_bin() {
    echo "$bin_block" | grep -q "  $1: true"
}

# --- Derived facts ---
PRIMARY_PM="unknown"
if has package_lock || has package_json; then PRIMARY_PM="npm"
elif has pnpm_lock; then PRIMARY_PM="pnpm"
elif has yarn_lock; then PRIMARY_PM="yarn"
elif has uv_lock; then PRIMARY_PM="uv"
elif has poetry_lock; then PRIMARY_PM="poetry"
elif has pipfile_lock; then PRIMARY_PM="pipenv"
elif has requirements; then PRIMARY_PM="pip"
elif has go_mod; then PRIMARY_PM="go"
elif has cargo_toml; then PRIMARY_PM="cargo"
elif has pom_xml; then PRIMARY_PM="maven"
elif has gradle; then PRIMARY_PM="gradle"
elif has composer; then PRIMARY_PM="composer"
elif has gemfile_lock; then PRIMARY_PM="bundler"
elif has csproj; then PRIMARY_PM="dotnet"
fi

HAS_CONTAINERS="false"
( has dockerfile || has containerfile || has compose || has docker_compose ) && HAS_CONTAINERS="true"

HAS_IAC="false"
( has terraform || has opentofu || has flake_nix ) && HAS_IAC="true"

HAS_CI="false"
( has gh_workflows || has gitlab_ci ) && HAS_CI="true"

# Detection stack — only list rule families the system can actually use
DETECTION_STACK=()
has_bin snort && DETECTION_STACK+=("snort")
has_bin suricata && DETECTION_STACK+=("suricata")
has_bin yara && DETECTION_STACK+=("yara")
has_bin nuclei && DETECTION_STACK+=("nuclei")
has_bin semgrep && DETECTION_STACK+=("semgrep")

# SBOM stack
SBOM_STACK=()
has_bin syft && SBOM_STACK+=("syft")
has_bin grype && SBOM_STACK+=("grype")
has_bin trivy && SBOM_STACK+=("trivy")
has_bin cosign && SBOM_STACK+=("cosign")

# SOAR / sink hint — heuristic
SOAR="none"
if grep -rq "stix" --include="*.yaml" --include="*.yml" --include="*.json" --include="*.md" . 2>/dev/null; then
    SOAR="stix"
fi

# Auth state
AUTH="unauthenticated"
if command -v vulnetix &>/dev/null; then
    AUTH_JSON=$(vulnetix auth status -o json 2>/dev/null || echo '{}')
    AUTH=$(echo "$AUTH_JSON" | jq -r '.status // "unauthenticated"' 2>/dev/null)
fi

yaml_list() {
    if [[ $# -eq 0 ]]; then echo "[]"; return; fi
    local out="[" first=1
    for v in "$@"; do
        if [[ $first -eq 1 ]]; then first=0; else out="${out}, "; fi
        out="${out}\"${v}\""
    done
    echo "${out}]"
}

# --- Write capabilities.yaml ---
{
cat <<HEADER
# .vulnetix/capabilities.yaml
# Auto-maintained by the Vulnetix Pix plugin (capabilities-detect hook).
# Other skills/hooks/commands/agents read this to scope their CLI surface
# to what this system + repo actually supports. Refreshed every 24h or on
# manifest edits. Force a refresh with: VULNETIX_FORCE_DETECT=1

schema_version: 1
detected_at: "${STAMP}"

binaries:
HEADER
printf '%s' "$bin_block"
echo "repo:"
printf '%s' "$repo_block"
cat <<DERIVED
derived:
  primary_package_manager: ${PRIMARY_PM}
  has_containers: ${HAS_CONTAINERS}
  has_iac: ${HAS_IAC}
  has_ci: ${HAS_CI}
  detection_stack: $(yaml_list "${DETECTION_STACK[@]}")
  sbom_stack: $(yaml_list "${SBOM_STACK[@]}")
  soar: ${SOAR}
  auth_status: ${AUTH}
DERIVED
} > "$CAP_FILE"

# Emit a brief systemMessage on first detection only
if [[ "${1:-}" == "--announce" ]]; then
    msg="Vulnetix capabilities detected: pm=${PRIMARY_PM}, containers=${HAS_CONTAINERS}, iac=${HAS_IAC}, detection=$(yaml_list "${DETECTION_STACK[@]}"), auth=${AUTH}"
    if [[ "${AUTH}" == "unauthenticated" ]]; then
        msg="${msg}. The VDB works unauthenticated on a shared pool; for a free Community key (higher limits) run /vulnetix:get-api-key — self-serve, no website visit needed."
    fi
    jq -n --arg m "$msg" '{systemMessage: $m}'
fi

exit 0
