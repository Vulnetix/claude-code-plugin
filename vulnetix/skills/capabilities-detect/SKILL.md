---
name: capabilities-detect
description: Re-probe system binaries and repo signals; refresh .vulnetix/capabilities.yaml so downstream skills know which Vulnetix CLI features are meaningful for this system+repo
user-invocable: true
allowed-tools: Bash, Read
model: haiku
---

# Vulnetix Capabilities Detector

This skill re-runs the capability probe and updates `.vulnetix/capabilities.yaml`. The file is read by every other Pix skill, hook, command, and agent to scope which Vulnetix CLI subcommands and external integrations (nuclei, snort, yara, semgrep, syft, grype, trivy, cosign, gh, package managers) are meaningful for the user's environment.

The session-start hook normally handles this automatically. Run this skill manually when:

- A new tool was just installed (e.g. `brew install yara`) and you want Pix to use it.
- The repo gained a new manifest, Dockerfile, or IaC layout.
- You want to inspect what Pix currently believes about your environment.

## Workflow

### Step 1: Force a refresh

```bash
VULNETIX_FORCE_DETECT=1 bash "${CLAUDE_PLUGIN_ROOT}/hooks/capabilities-detect.sh" --announce
```

If `${CLAUDE_PLUGIN_ROOT}` is not set in the user's shell, locate the plugin root via `$HOME/.claude/plugins/vulnetix` or run the script directly from the plugin checkout.

### Step 2: Render the result

Read `.vulnetix/capabilities.yaml` and present a compact summary to the user:

```
Capabilities (detected <timestamp>):
- Package manager: <derived.primary_package_manager>
- Containers in repo: <derived.has_containers>
- IaC in repo: <derived.has_iac>
- CI configured: <derived.has_ci>
- Detection stack: <derived.detection_stack>
- SBOM stack: <derived.sbom_stack>
- SOAR sink: <derived.soar>
- Vulnetix auth: <derived.auth_status>
```

Then surface relevant follow-ups based on what was found, e.g. "Trivy is installed — `/vulnetix:container-scan` will compose its output", "No SAST binary detected — `/vulnetix:sast-scan` will use built-in Vulnetix rules only".

### Step 3: Output policy

This skill never modifies application code, manifests, or memory.yaml. It only refreshes `capabilities.yaml`.

## Schema reference

See `website/content/docs/data-structures/capabilities-yaml.md` for the full schema. Three top-level sections: `binaries`, `repo`, `derived`. The `derived.detection_stack`, `derived.sbom_stack`, `derived.primary_package_manager`, and `derived.has_*` flags are the fields most other skills consult.
