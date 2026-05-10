---
name: dep-install-gate
description: Pre-install informational gate — quick vuln/malware check on packages being added via npm/pnpm/yarn/pip/uv/cargo/go/gem/composer
event: command
---

PreToolUse hook on Bash. Detects `npm i`, `pnpm add`, `yarn add`, `pip install`, `uv add`, `cargo add`, `go get`, `gem install`, `composer require` commands, extracts the package name, and runs a quick `vulnetix vdb vulns` + `ai-malware` check. Always informational (exit 0); never blocks. Suggests `/vulnetix:dep-add-guard` for full assessment.
