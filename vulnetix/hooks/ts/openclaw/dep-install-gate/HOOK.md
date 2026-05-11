---
name: dep-install-gate
description: 'PreToolUse Bash gate: detect `npm/pnpm/yarn add`, `pip/uv install`, `cargo add`, `go get`, `gem install`, `composer require`; extract package name; run a quick `vdb vulns` + `ai-malware` check before the install runs. Cooldown keyed on `package@ecosystem`. Use when guarding casual `npm install x` invocations without blocking.'
event: command
---

# Dep-Install-Gate hook

## Use when

- A Bash command matches a known install pattern.
- The package has not already been warned-about this session.


PreToolUse hook on Bash. Detects `npm i`, `pnpm add`, `yarn add`, `pip install`, `uv add`, `cargo add`, `go get`, `gem install`, `composer require` commands, extracts the package name, and runs a quick `vulnetix vdb vulns` + `ai-malware` check. Always informational (exit 0); never blocks. Suggests `/vulnetix:dep-add-guard` for full assessment.

## Edge cases & gotchas

- Package-name regex is per-PM; scoped npm packages (`@scope/name`) need the `@`-prefix handling.
- `-D`/`--save-dev` flags do not affect the warning — both dev and runtime additions get the same check.
- Cooldown key includes the ecosystem; the same package across npm + pypi warns twice.
- Hook is informational (exit 0) — never blocks the install.
- Two parallel `npm i a b c` invocations only warn on the first package (sequential parsing).
